require 'base32/crockford'
require 'uri'

class ClientPrefixesController < ApplicationController
  before_action :set_client_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    # support nested routes
    if params[:id].present?
      collection = ClientPrefix.where(id: params[:id])
    elsif params[:client_id].present? && params[:prefix_id].present?
      collection = ClientPrefix.joins(:client, :prefix).where('datacentre.symbol = ?', params[:client_id]).where('prefix.prefix = ?', params[:prefix_id])
    elsif params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.client_prefixes.joins(:prefix) : ClientPrefix.none
    elsif params[:prefix_id].present?
      prefix = Prefix.where('prefix.prefix = ?', params[:prefix_id]).first
      collection = prefix.present? ? prefix.client_prefixes.joins(:client) : ClientPrefix.none
    else
      collection = ClientPrefix.joins(:client, :prefix)
    end

    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(datacentre_prefixes.created_at) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(datacentre_prefixes.created_at) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefixes: nil).order("datacentre_prefixes.created_at DESC").group("YEAR(datacentre_prefixes.created_at)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    order = case params[:sort]
            when "name" then "prefix.prefix"
            when "-name" then "prefix.prefix DESC"
            when "created" then "datacentre_prefixes.created_at"
            else "datacentre_prefixes.created_at DESC"
            end

    @client_prefixes = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @client_prefixes.total_pages,
             page: page[:number].to_i,
             years: years }

    render jsonapi: @client_prefixes, meta: meta, include: @include
  end

  def show
    render jsonapi: @client_prefix, include: @include, serializer: ClientPrefixSerializer
  end

  def create
    @client_prefix = ClientPrefix.new(safe_params)
    authorize! :create, @client_prefix

    if @client_prefix.save
      render jsonapi: @client_prefix, status: :created, location: @client_prefix
    else
      Rails.logger.warn @client_prefix.errors.inspect
      render jsonapi: serialize(@client_prefix.errors), status: :unprocessable_entity
    end
  end

  def destroy
    @client_prefix.destroy
    head :no_content
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = ['client', 'prefix', 'provider_prefix', 'provider']
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_client_prefix
    id = Base32::Crockford.decode(URI.decode(params[:id]).upcase)
    fail ActiveRecord::RecordNotFound unless id.present?

    @client_prefix = ClientPrefix.where(id: id.to_i).first

    fail ActiveRecord::RecordNotFound unless @client_prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :client, :prefix, :provider_prefix]
    )
  end
end
