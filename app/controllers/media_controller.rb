class MediaController < ApplicationController
  before_action :set_doi
  before_action :set_media, only: [:show, :update, :destroy]
  before_action :set_include
  before_action :authenticate_user!

  def index
    collection = @doi.media
    total = @doi.cached_media_count.reduce(0) { |sum, d| sum + d[:count].to_i }

    page = page_from_params(params)
    total_pages = (total.to_f / page[:size]).ceil

    order = case params[:sort]
            when "name" then "dataset.doi"
            when "-name" then "dataset.doi DESC"
            when "created" then "media.created"
            else "media.created DESC"
            end

    @media = collection.order(order).page(page[:number]).per(page[:size])

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => total_pages,
      page: page[:number].to_i
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @media.blank? ? nil : request.base_url + "/media?" + {
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: MediaSerializer.new(@media, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: MediaSerializer.new(@media, options).serialized_json, status: :ok
  end

  def create
    authorize! :update, @doi

    @media = Media.new(safe_params.merge(doi: @doi))

    if @media.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: MediaSerializer.new(@media, options).serialized_json, status: :created
    else
      Rails.logger.error @media.errors.inspect
      render json: serialize_errors(@media.errors), status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @doi

    if @media.update_attributes(safe_params.merge(doi: @doi))
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: MediaSerializer.new(@media, options).serialized_json, status: :ok
    else
      Rails.logger.error @media.errors.inspect
      render json: serialize_errors(@media.errors), status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :update, @doi

    if @media.destroy
      head :no_content
    else
      Rails.logger.error @media.errors.inspect
      render json: serialize_errors(@media.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:doi_id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_media
    id = Base32::URL.decode(URI.decode(params[:id]))
    fail ActiveRecord::RecordNotFound unless id.present?

    @media = Media.where(id: id.to_i).first
    fail ActiveRecord::RecordNotFound unless @media.present?
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
      params, only: ["mediaType", :url],
              keys: { "mediaType" => :media_type }
    )
  end
end
