class ProvidersController < ApplicationController
  before_action :set_provider, only: [:show, :update, :destroy, :getpassword]
  before_action :set_include, :authenticate_user_from_token!
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Provider

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    puts collection

    # cache prefixes for faster queries
    if params[:prefix].present?
      prefix = cached_prefix_response(params[:prefix])
      collection = collection.includes(:prefixes).where('prefix.id' => prefix.id)
    end

    if params[:client_id].present?
      client = cached_client_response(params[:client_id].upcase)
      collection = collection.includes(:clients).where('datacentre.id' => client.id)
    end

    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where("YEAR(allocator.created) = ?", params[:year]) if params[:year].present?

    if params[:region].present?
      regions = [{ id: params[:region],
                   title: REGIONS[params[:region].upcase],
                   count: collection.where(region: params[:region]).count }]
    else
      regions = collection.where.not(region: nil).group(:region).count
      regions = regions.map { |k,v| { id: k.downcase, title: REGIONS[k], count: v } }
    end
    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where("YEAR(allocator.created) = ?", params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(allocator.created) DESC").group("YEAR(allocator.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    order = case params[:sort]
            when "name" then "allocator.name"
            when "-name" then "allocator.name DESC"
            when "created" then "allocator.created"
            else "allocator.created DESC"
            end

    @providers = collection.order(order).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @providers.total_pages,
             page: page[:number].to_i,
             regions: regions,
             years: years
           }

    render jsonapi: @providers, meta: meta, include: @include
  end

  def show
    meta = { providers: @provider.provider_count,
             clients: @provider.client_count,
             dois: @provider.doi_count }.compact

    render jsonapi: @provider, meta: meta, include: @include
  end

  # POST /providers
  def create
    @provider = Provider.new(safe_params)
    authorize! :create, @provider

    if @provider.save
      render jsonapi: @provider, status: :created, location: @provider
    else
      Rails.logger.warn @provider.errors.inspect
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /providers/1
  def update
    if @provider.update_attributes(safe_params)
      render jsonapi: @provider
    else
      Rails.logger.warn @provider.errors.inspect
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a provider with clients or prefixes can't be deleted
  def destroy
    if @provider.clients.present? || @provider.prefixes.present?
      message = "Can't delete provider that has clients or prefixes."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @provider.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      head :no_content
    else
      Rails.logger.warn @provider.errors.inspect
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  def getpassword
    phrase = Password.new(current_user, @provider)
    response.headers['X-Consumer-Role'] = current_user && current_user.role_id || 'anonymous'
    r = {password: phrase.string }
    render jsonapi: @client, meta: r , include: @include
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end

  private

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = nil
    end
  end

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:name, :symbol, :contact_name, :contact_email, :country, :is_active],
              keys: { country: :country_code }
    )
  end
end
