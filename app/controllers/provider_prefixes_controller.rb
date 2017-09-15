class ProviderPrefixesController < ApplicationController
  before_action :set_provider_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user_from_token!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show]

  def index
    # support nested routes
    if params[:id].present?
      collection = ProviderPrefix.where(id: params[:id])
    elsif params[:provider_id].present? && params[:prefix_id].present?
      collection = ProviderPrefix.joins(:provider, :prefix).where('allocator.symbol = ?', params[:provider_id]).where('prefix.prefix = ?', params[:prefix_id])
    elsif params[:provider_id].present?
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? provider.provider_prefixes.joins(:prefix) : ProviderPrefix.none
    elsif params[:prefix_id].present?
      prefix = Prefix.where('prefix.prefix = ?', params[:prefix_id]).first
      collection = prefix.present? ? prefix.provider_prefixes.joins(:provider) : ProviderPrefix.none
    else
      collection = ProviderPrefix.joins(:provider, :prefix)
    end

    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(allocator_prefixes.created) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(allocator_prefixes.created) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefixes: nil).order("allocator_prefixes.created DESC").group("YEAR(allocator_prefixes.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # calculate facet counts after filtering
    # no faceting by client
    if provider.present?
      providers = [{ id: params[:provider_id],
                     title: provider.name,
                     count: collection.where('allocator_prefixes.allocator' => provider.id).count }]
    else
      providers = collection.where.not('allocator_prefixes.allocator' => nil).group('allocator_prefixes.allocator').count
      providers = providers
                  .sort { |a, b| b[1] <=> a[1] }
                  .reduce([]) do |sum, i|
                                if provider = cached_providers.find { |m| m.id == i[0] }
                                  sum << { id: provider.symbol.downcase, title: provider.name, count: i[1] }
                                end

                                sum
                              end
    end

    # pagination
    page = params[:page] || {}
    page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
    page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
    total = collection.count

    @provider_prefixes = collection.order(created: :desc).page(page[:number]).per(page[:size])

    meta = { total: total,
             total_pages: @provider_prefixes.total_pages,
             page: page[:number].to_i,
             providers: providers,
             years: years }

    render jsonapi: @provider_prefixes, meta: meta, include: @include
  end

  # GET /prefixes/1
  def show
    render jsonapi: @provider_prefix, include: @include, serializer: PrefixSerializer
  end

  # POST /prefixes
  def create
    @provider_prefix = Prefix.new(safe_params)
    authorize! :create, @provider_prefix

    if @provider_prefix.save
      render jsonapi: @provider_prefix, status: :created, location: @provider_prefix
    else
      Rails.logger.warn @provider_prefix.errors.inspect
      render jsonapi: serialize(@provider_prefix.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /prefixes/1
  def update
    if @provider_prefix.update_attributes(safe_params)
      render jsonapi: @provider_prefix
    else
      Rails.logger.warn @provider_prefix.errors.inspect
      render json: serialize(@provider_prefix.errors), status: :unprocessable_entity
    end
  end

  # DELETE /prefixes/1
  def destroy
    @provider_prefix.destroy
    head :no_content
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = ['client', 'provider', 'prefix']
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_provider_prefix
    id = Base32::Crockford.decode(URI.decode(params[:id]).upcase, checksum: true)
    fail ActiveRecord::RecordNotFound unless id.present?

    @provider_prefix = ProviderPrefix.where(id: id.to_i).first
    fail ActiveRecord::RecordNotFound unless @provider_prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :provider, :created, :updated],
              keys: { id: :prefix }
    )
  end
end
