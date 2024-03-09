# frozen_string_literal: true

class MetadataController < ApplicationController
  before_action :set_doi
  before_action :set_metadata, only: %i[show destroy]
  before_action :set_include
  before_action :authenticate_user!

  def index
    @doi = DataciteDoi.includes(:metadata).find_by(doi: params[:doi_id])
    fail ActiveRecord::RecordNotFound if @doi.blank?

    collection = @doi.metadata
    total =
      @doi.cached_metadata_count.reduce(0) { |sum, d| sum + d[:count].to_i }

    page = page_from_params(params)
    total_pages = (total.to_f / page[:size]).ceil

    order =
      case params[:sort]
      when "name"
        "dataset.doi"
      when "-name"
        "dataset.doi DESC"
      when "created"
        "metadata.created"
      else
        "metadata.created DESC"
      end

    @metadata = collection.order(order).page(page[:number]).per(page[:size])

    options = {}
    options[:meta] = {
      total: total, "totalPages" => total_pages, page: page[:number].to_i
    }.compact

    options[:links] = {
      self: request.original_url,
      next:
        if @metadata.blank? || page[:number] == total_pages
          nil
        else
          request.base_url + "/media?" +
            {
              "page[number]" => page[:number] + 1,
              "page[size]" => page[:size],
              sort: params[:sort],
            }.compact.
            to_query
        end,
    }.compact
    options[:include] = @include
    options[:is_collection] = true

    render(
      json: MetadataSerializer.new(@metadata, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render(
      json: MetadataSerializer.new(@metadata, options).serializable_hash.to_json,
      status: :ok
    )
  end

  def create
    authorize! :update, @doi

    # convert back to plain xml
    xml = safe_params[:xml].present? ? Base64.decode64(safe_params[:xml]) : nil
    @metadata = Metadata.new(safe_params.merge(doi: @doi, xml: xml))

    if @metadata.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render(
        json: MetadataSerializer.new(@metadata, options).serializable_hash.to_json,
        status: :created
      )
    else
      Rails.logger.error @metadata.errors.inspect
      render json: serialize_errors(@metadata.errors),
             status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :update, @doi

    if @doi.draft?
      if @metadata.destroy
        head :no_content
      else
        Rails.logger.error @metadata.errors.inspect
        render json: serialize_errors(@metadata.errors),
               status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: {
        errors: [{ status: "405", title: "Method not allowed" }],
      }.to_json,
             status: :method_not_allowed
    end
  end

  protected
    def set_doi
      @doi = DataciteDoi.where(doi: params[:datacite_doi_id]).first
      fail ActiveRecord::RecordNotFound if @doi.blank?
    end

    def set_metadata
      id = Base32::URL.decode(CGI.unescape(params[:id]))
      fail ActiveRecord::RecordNotFound if id.blank?

      @metadata = Metadata.where(id: id.to_i).first
      fail ActiveRecord::RecordNotFound if @metadata.blank?
    end

    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & %i[doi]
      else
        @include = []
      end
    end

  private
    def safe_params
      if params[:data].blank?
        fail JSON::ParserError,
             "You need to provide a payload following the JSONAPI spec"
      end

      ActiveModelSerializers::Deserialization.jsonapi_parse!(
        params,
        only: %i[xml],
      )
    end
end
