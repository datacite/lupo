class ProviderPrefixesController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :set_provider_prefix, only: [:show, :update, :destroy]
  before_action :set_include
  authorize_resource :except => [:index, :show]

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

    collection = collection.state(params[:state]) if params[:state].present?
    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(allocator_prefixes.created_at) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(allocator_prefixes.created_at) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefixes: nil).order("YEAR(allocator_prefixes.created_at) DESC").group("YEAR(allocator_prefixes.created_at)").count
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
                                if provider = Provider.where(symbol: i[0]).first
                                  sum << { id: provider.symbol.downcase, title: provider.name, count: i[1] }
                                end

                                sum
                              end
    end

    if params[:state].present?
      states = [{ id: params[:state],
                  title: params[:state].underscore.humanize,
                  count: collection.count }]
    else
      states = [{ id: "without-client",
                  title: "Without client",
                  count: collection.state("without-client").count },
                { id: "with-client",
                  title: "With client",
                  count: collection.state("with-client").count }]
    end

    page = page_from_params(params)
    total = collection.count

    order = case params[:sort]
            when "name" then "prefix.prefix"
            when "-name" then "prefix.prefix DESC"
            when "created" then "allocator_prefixes.created_at"
            else "allocator_prefixes.created_at DESC"
            end

    @provider_prefixes = collection.order(order).page(page[:number]).per(page[:size])

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => @provider_prefixes.total_pages,
      page: page[:number],
      states: states,
      providers: providers,
      years: years
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @provider_prefixes.blank? ? nil : request.base_url + "/provider-prefixes?" + {
        query: params[:query],
        "provider-id" => params[:provider_id],
        "prefix-id" => params[:prefix_id],
        year: params[:year],
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: ProviderPrefixSerializer.new(@provider_prefixes, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: ProviderPrefixSerializer.new(@provider_prefix, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    @provider_prefix = ProviderPrefix.new(safe_params)
    authorize! :create, @provider_prefix

    if @provider_prefix.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ProviderPrefixSerializer.new(@provider_prefix, options).serialized_json, status: :created
    else
      logger.warn @provider_prefix.errors.inspect
      render json: serialize(@provider_prefix.errors), status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, DELETE, OPTIONS"
    render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
  end

  def destroy
    @provider_prefix.destroy
    head :no_content
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:provider, :prefix, :clients]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = [:provider, :prefix, :clients]
    end
  end

  private

  def set_provider_prefix
    id = Base32::URL.decode(URI.decode(params[:id]))
    fail ActiveRecord::RecordNotFound unless id.present?

    @provider_prefix = ProviderPrefix.where(id: id.to_i).first
    fail ActiveRecord::RecordNotFound unless @provider_prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :provider, :prefix]
    )
  end
end
