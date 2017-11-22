require 'uri'

class DoisController < ApplicationController
  before_action :set_doi, only: [:show, :update, :destroy]
  before_action :set_include
  before_action :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  def index
    # support nested routes
    if params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.dois : Doi.none
      total = client.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    elsif params[:provider_id].present?
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? Doi.joins(:client).where("datacentre.allocator = ?", provider.id) : Doi.none
      total = provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    elsif params[:id].present?
      collection = Doi.where(doi: params[:id])
      total = collection.all.size
    else
      provider = Provider.unscoped.where('allocator.symbol = ?', "ADMIN").first
      collection = Doi
      total = provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    end

    if params[:query].present?
      collection = Doi.query(params[:query])
      total = collection.all.size
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total_pages = (total.to_f / page[:size]).ceil

    order = case params[:sort]
    when "name" then "dataset.doi"
            when "-name" then "dataset.doi DESC"
            when "created" then "dataset.created"
            else "dataset.created DESC"
            end

    @dois = collection.order(order).page(page[:number]).per(page[:size]).without_count

    meta = { total: total,
             total_pages: total_pages,
             page: page[:number].to_i }

    render jsonapi: @dois, meta: meta, each_serializer: DoiSerializer
  end

  def show
    render jsonapi: @doi, include: @include, serializer: DoiSerializer
  end

  def create
    @doi = Doi.new(safe_params)
    authorize! :create, @doi

    if @doi.save
      render jsonapi: @doi, status: :created, location: @doi
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  def update
    if @doi.update_attributes(safe_params)
      render jsonapi: @provider
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  def destroy
    if @doi.remove
      head :no_content
    else
      Rails.logger.warn @doi.errors.inspect
      render jsonapi: serialize(@doi.errors), status: :unprocessable_entity
    end
  end

  def set_state

  end

  def delete_test_dois

  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["client,provider,resource_type"]
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    Rails.logger.warn params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:uid, :created, :doi, :url, :version, :client]
    )
  end
end
