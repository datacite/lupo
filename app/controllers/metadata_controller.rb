class MetadataController < ApplicationController
  before_action :set_doi
  before_action :set_metadata, only: [:show, :destroy]
  before_action :set_include
  before_action :authenticate_user!

  def index
    @doi = Doi.where(doi: params[:doi_id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?

    collection = @doi.metadata
    total = @doi.cached_metadata_count.reduce(0) { |sum, d| sum + d[:count].to_i }

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

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => total_pages,
      page: page[:number].to_i
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @metadata.blank? ? nil : request.base_url + "/media?" + {
        "page[number]" => params.dig(:page, :number).to_i + 1,
        "page[size]" => params.dig(:page, :size),
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: MetadataSerializer.new(@metadata, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: MetadataSerializer.new(@metadata, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    authorize! :update, @doi

    # convert back to plain xml
    xml = safe_params[:xml].present? ? Base64.decode64(safe_params[:xml]) : nil
    @metadata = Metadata.new(safe_params.merge(doi: @doi, xml: xml))

    if @metadata.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: MetadataSerializer.new(@metadata, options).serialized_json, status: :created
    else
      logger.warn @metadata.errors.inspect
      render json: serialize(@metadata.errors), status: :unprocessable_entity
    end
  end

  def destroy
    logger = Logger.new(STDOUT)
    authorize! :update, @doi

    if @doi.draft?
      if @metadata.destroy
        head :no_content
      else
        logger.warn @metadata.errors.inspect
        render json: serialize(@metadata.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:doi_id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_metadata
    id = Base32::URL.decode(URI.decode(params[:id]))
    fail ActiveRecord::RecordNotFound unless id.present?

    @metadata = Metadata.where(id: id.to_i).first
    fail ActiveRecord::RecordNotFound unless @metadata.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:doi]
    else
      @include = [:doi]
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:xml]
    )
  end
end
