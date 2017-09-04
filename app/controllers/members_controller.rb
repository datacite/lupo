class MembersController < ApplicationController
  before_action :set_provider, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    collection = Member

    if params[:id].present?
      collection = collection.where(symbol: params[:id])
    elsif params[:query].present?
      collection = collection.query(params[:query])
    end

    collection = collection.where(provider_type: params['provider-type']) if params['provider-type'].present?
    collection = collection.where(region: params[:region]) if params[:region].present?
    collection = collection.where(year: params[:year]) if params[:year].present?

    # calculate facet counts after filtering
    if params["provider-type"].present?
      provider_types = [{ id: params["provider-type"],
                        title: params["provider-type"].humanize,
                        count: collection.where(provider_type: params["provider-type"]).count }]
    else
      provider_types = collection.where.not(provider_type: nil).group(:provider_type).count
      provider_types = provider_types.map { |k,v| { id: k, title: k.humanize, count: v } }
    end
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
             provider_types: provider_types,
             regions: regions,
             years: years }

    render jsonapi: @providers, meta: meta, include: @include
  end

  def show
    render jsonapi: @provider
  end

  # POST /providers
  def create
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render jsonapi: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      @provider = Member.new(safe_params.except(:type))
      authorize! :create, @provider

      if @provider.save
        render jsonapi: @provider, status: :created, location: @provider
      else
        render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /providers/1
  def update
    unless [:type, :attributes].all? { |k| safe_params.key? k }
      render jsonapi: { errors: [{ status: 422, title: "Missing attribute: type."}] }, status: :unprocessable_entity
    else
      if @provider.update_attributes(safe_params.except(:type))
        render jsonapi: @provider
      else
        render jsonapi: serialize(@provider.errors), status: :unprocessable_entity
      end
    end
  end

  # DELETE /providers/1
  def destroy
    @provider.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Member.where(symbol: params[:id]).first
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

  # Only allow a trusted parameter "white list" through.
  def safe_params
    attributes = [:uid, :name, :contact_email, :contact_name, :description, :year, :region, :country_code, :website, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :provider_id, :version]
    # ActiveModelSerializers::Deserialization.jsonapi_parse!(params.to_unsafe_h)[:prefixes_ids]
    relationships = [:relationships, :prefixes]
    params.require(:data).permit(:id, :type, attributes: attributes, prefixes_attributes: relationships)

  end

  # Only allow a trusted parameter "white list" through.
  # def provider_params
  #   params.require(:data)
  #     .require(:attributes)
  #     .permit(:uid, :name, :contact_email, :contact_name, :description, :year, :region, :country_code, :website, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :provider_id, :version)
  #
  #   mb_params= ActiveModelSerializers::Deserialization.jsonapi_parse(params).transform_keys!{ |key| key.to_s.snakecase }
  #   mb_params["password"] = encrypt_password(mb_params["password"])
  #   mb_params
  # end
end
