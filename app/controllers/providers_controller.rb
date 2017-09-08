class ProvidersController < ApplicationController
  before_action :set_provider, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Provider

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    # collection = collection.where(provider_type: params['provider-type']) if params['provider-type'].present?
    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where(year: params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    # if params["provider-type"].present?
    #   provider_types = [{ id: params["provider-type"],
    #                     title: params["provider-type"].humanize,
    #                     count: collection.where(provider_type: params["provider-type"]).count }]
    # else
    #   provider_types = collection.where.not(provider_type: nil).group(:provider_type).count
    #   provider_types = provider_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    # end
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
                 count: collection.where(year: params[:year]).count }]
    else
      years = collection.where.not(created: nil).order("YEAR(created) DESC").group("YEAR(created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @providers = collection.order(:name).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @providers.total_pages,
             page: page[:number].to_i,
            #  provider_types: provider_types,
             regions: regions,
             years: years }

    render jsonapi: @providers, meta: meta, include: @include
  end

  def show
    render jsonapi: @provider
  end

  # POST /providers
  def create
    @provider = Provider.new(safe_params)
    authorize! :create, @provider

    if @provider.save
      render jsonapi: @provider, status: :created, location: @provider
    else
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /providers/1
  def update
    if @provider.update_attributes(safe_params)
      render jsonapi: @provider
    else
      Rails.logger.info @provider.errors.inspect
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a provider with clients or prefixes can't be deleted
  def destroy
    if @provider.clients || @provider.prefixes
      message = "Can't delete provider that has clients or prefixes."
      status = 400
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @provider.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      head :no_content
    else
      Rails.logger.warn @provider.errors.inspect
      render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.where(symbol: params[:id]).first
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
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:name, :contact, :email, :country, :is_active],
              keys: { contact: :contact_name, email: :contact_email, country: :country_code }
    )
  end
end
