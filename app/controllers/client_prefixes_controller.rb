class ClientPrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  # GET /prefixes
  def index
    # support nested routes
    if params[:id].present?
      collection = ClientPrefix.where(id: params[:id])
    elsif params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.client_prefixes.joins(:prefix) : ClientPrefix.none
    else
      collection = ClientPrefix.joins(:client, :prefix)
    end

    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(datacentre_prefixes.created) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(datacentre_prefixes.created) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefixes: nil).order("datacentre_prefixes.created DESC").group("YEAR(datacentre_prefixes.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @client_prefixes = collection.order(created: :desc).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @client_prefixes.total_pages,
             page: page[:number].to_i,
             years: years }

    render jsonapi: @client_prefixes, meta: meta, include: @include
  end

  # GET /prefixes/1
  def show
    render jsonapi: @client_prefix, include: @include, serializer: PrefixSerializer
  end

  # POST /prefixes
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

  # PATCH/PUT /prefixes/1
  def update
    if @client_prefix.update_attributes(safe_params)
      render jsonapi: @client_prefix
    else
      Rails.logger.warn @client_prefix.errors.inspect
      render json: serialize(@client_prefix.errors), status: :unprocessable_entity
    end
  end

  # DELETE /prefixes/1
  def destroy
    @client_prefix.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = ['client','prefix']
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_prefix
    @client_prefix = ProviderPrefix.where(prefix: params[:id]).first

    fail ActiveRecord::RecordNotFound unless @client_prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :clients, :providers, :created],
              keys: { id: :prefix }
    )
  end
end
