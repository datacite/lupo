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
    render jsonapi: @client
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
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render json: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @client.update_attributes(safe_params.except(:type))
        render jsonapi: @client
      else
        render json: serialize(@client.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /clients/1
  def destroy
    @client.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_client
    @client = Client.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client.present?
  end

  private

  # Only allow a trusted parameter "white list" through.
  def safe_params
    attributes = [:uid, :name, :contact_email, :contact_name, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :password, :role_name, :version, :provider_id]
    params.require(:data).permit(:id, :type, attributes: attributes)
  end

  # # Only allow a trusted parameter "white list" through.
  # def client_params
  #   dc_params = ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   allocator = Member.find_by(symbol: dc_params["provider_id"])
  #   fail("provider_id Not found") unless allocator.present?
  #   dc_params["allocator"] = allocator.id
  #   dc_params["password"] = encrypt_password(dc_params["password"])
  #   dc_params["symbol"] = dc_params["client_id"]
  #   dc_params
  # end
end
