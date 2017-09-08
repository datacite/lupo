class ClientsController < ApplicationController
  before_action :set_client, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Client

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # cache providers for faster queries
    if params["provider-id"].present?
      provider = cached_provider_response(params["provider-id"].upcase)
      collection = collection.where(allocator: provider.id)
    end
    collection = collection.where('YEAR(created) = ?', params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    if params["provider-id"].present?
      providers = [{ id: params["provider-id"],
                   title: provider.name,
                   count: collection.where(allocator: provider.id).count }]
    else
      providers = collection.where.not(allocator: nil).group(:allocator).count
      Rails.logger.info providers.inspect
      providers = providers
                  .sort { |a, b| b[1] <=> a[1] }
                  .map do |i|
                         provider = cached_providers.find { |m| m.id == i[0] }
                         { id: provider.symbol.downcase, title: provider.name, count: i[1] }
                       end
    end
    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(created) = ?', params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @clients = collection.order(:name).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @clients.total_pages,
             page: page[:number].to_i,
             providers: providers,
             years: years }

    render jsonapi: @clients, meta: meta, include: @include
  end

  # GET /clients/1
  def show
    render jsonapi: @client, include: @include
  end

  # POST /clients
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @client = Client.new(safe_params.except(:type))
      authorize! :create, @client

      if @client.save
        render jsonapi: @client, status: :created, location: @client
      else
        render jsonapi: serialize(@client.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /clients/1
  def update
    if @client.update_attributes(safe_params)
      render jsonapi: @client
    else
      Rails.logger.warn @client.errors.inspect
      render json: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a client with dois or prefixes can't be deleted
  def destroy
    if @client.datasets || @client.prefixes
      message = "Can't delete client that has DOIs or prefixes."
      status = 400
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @client.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      head :no_content
    else
      Rails.logger.warn @client.errors.inspect
      render jsonapi: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["provider"]
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_client
    @client = Client.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client.present?
  end

  private

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:name, :contact, :email, :domains, :provider, :is_active],
              keys: { contact: :contact_name, email: :contact_email }
    )
  end
end
