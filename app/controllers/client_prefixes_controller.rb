require 'base32/url'
require 'uri'

class ClientPrefixesController < ApplicationController
  before_action :set_client_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show, :set_created, :set_provider]

  def index
    # support nested routes
    if params[:id].present?
      collection = ClientPrefix.where(id: params[:id])
    elsif params[:client_id].present? && params[:prefix_id].present?
      collection = ClientPrefix.joins(:client, :prefix).where('datacentre.symbol = ?', params[:client_id]).where('prefix.uid = ?', params[:prefix_id])
    elsif params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.client_prefixes.joins(:prefix) : ClientPrefix.none
    elsif params[:prefix_id].present?
      prefix = Prefix.where('prefix.uid = ?', params[:prefix_id]).first
      collection = prefix.present? ? prefix.client_prefixes.joins(:client) : ClientPrefix.none
    else
      collection = ClientPrefix.joins(:client, :prefix)
    end

    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(client_prefixes.created_at) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(client_prefixes.created_at) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefix_id: nil).order("YEAR(client_prefixes.created_at) DESC").group("YEAR(client_prefixes.created_at)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = page_from_params(params)
    total = collection.count

    order = case params[:sort]
            when "name" then "prefix.uid"
            when "-name" then "prefix.uid DESC"
            when "created" then "client_prefixes.created_at"
            else "client_prefixes.created_at DESC"
            end

    @client_prefixes = collection.order(order).page(page[:number]).per(page[:size])

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => @client_prefixes.total_pages,
      page: page[:number].to_i,
      years: years
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @client_prefixes.blank? ? nil : request.base_url + "/client-prefixes?" + {
        query: params[:query],
        year: params[:year],
        "page[number]" => params.dig(:page, :number).to_i + 1,
        "page[size]" => params.dig(:page, :size),
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: ClientPrefixSerializer.new(@client_prefixes, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: ClientPrefixSerializer.new(@client_prefix, options).serialized_json, status: :ok
  end

  def create
    @client_prefix = ClientPrefix.new(safe_params)
    authorize! :create, @client_prefix

    if @client_prefix.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ClientPrefixSerializer.new(@client_prefix, options).serialized_json, status: :created
    else
      Rails.logger.error @client_prefix.errors.inspect
      render json: serialize_errors(@client_prefix.errors), status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, DELETE, OPTIONS"
    render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
  end

  def destroy
    @client_prefix.destroy
    head :no_content
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:client, :prefix, :provider_prefix, :provider]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = [:client, :prefix, :provider_prefix, :provider]
    end
  end

  private

  def set_client_prefix
    @client_prefix = ClientPrefix.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client_prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :client, :prefix, :providerPrefix],
      keys: { "providerPrefix" => :provider_prefix }
    )
  end
end
