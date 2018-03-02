class MetadataController < ApplicationController
  before_action :set_metadata, only: [:show, :destroy]
  before_action :set_include
  before_action :authenticate_user!
  load_and_authorize_resource :except => [:index, :show, :convert]

  def index
    if params[:doi_id].present?
      doi = Doi.where(doi: params[:doi_id]).first
      collection = doi.present? ? doi.metadata : Metadata.none
      total = doi.cached_metadata_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    else
      collection = Metadata.joins(:doi)
      total = Metadata.cached_metadata_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total_pages = (total.to_f / page[:size]).ceil

    order = case params[:sort]
            when "name" then "dataset.doi"
            when "-name" then "dataset.doi DESC"
            when "created" then "metadata.created"
            else "metadata.created DESC"
            end

    @metadata = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: total_pages,
             page: page[:number].to_i }

    render jsonapi: @metadata, meta: meta, include: @include
  end

  def show
    render jsonapi: @metadata, include: @include
  end

  def create
    @metadata = Metadata.new(safe_params)
    authorize! :create, @metadata

    if @metadata.save
      render jsonapi: @metadata, status: :created
    else
      Rails.logger.warn @metadata.errors.inspect
      render jsonapi: serialize(@metadata.errors), status: :unprocessable_entity
    end
  end

  def destroy
    if @metadata.doi.draft?
      if @metadata.destroy
        head :no_content
      else
        Rails.logger.warn @metadata.errors.inspect
        render jsonapi: serialize(@metadata.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  def convert
    @metadata = Metadata.new(safe_params.merge(regenerate: true))

    if @metadata.validation_errors?
      Rails.logger.warn @metadata.validation_errors.inspect
      render jsonapi: { "errors" => @metadata.validation_errors }.to_json, status: :unprocessable_entity
    else
      render jsonapi: @metadata, status: :ok
    end
  end

  protected

  def set_metadata
    id = Base32::URL.decode(URI.decode(params[:id]))
    fail ActiveRecord::RecordNotFound unless id.present?

    @metadata = Metadata.where(id: id.to_i).first
    fail ActiveRecord::RecordNotFound unless @metadata.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = []
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:xml, :doi, :regenerate]
    )
  end
end
