class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show, :totals]

  def index
    # support nested routes
    if params[:id].present?
      collection = Prefix.where(prefix: params[:id])
    elsif params[:provider_id].present?
      provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
      collection = provider.present? ? provider.prefixes : Prefix.none
    elsif params[:client_id].present?
      client = Client.where('datacentre.symbol = ?', params[:client_id]).first
      collection = client.present? ? client.prefixes : Prefix.none
    else
      collection = Prefix
    end

    collection = collection.state(params[:state]) if params[:state].present?
    collection = collection.query(params[:query]) if params[:query].present?
    collection = collection.where('YEAR(prefix.created) = ?', params[:year]) if params[:year].present?

    if params[:year].present?
      years = [{ id: params[:year],
                 title: params[:year],
                 count: collection.where('YEAR(prefix.created) = ?', params[:year]).count }]
    else
      years = collection.where.not(prefix: nil).order("YEAR(prefix.created) DESC").group("YEAR(prefix.created)").count
      years = years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    end

    # calculate facet counts after filtering
    # no faceting by client
    if params[:provider_id].present?
      providers = [{ id: params[:provider_id],
                     title: provider.name,
                     count: collection.includes(:providers).where('allocator.id' => provider.id).count }]
    else
      providers = collection.includes(:providers).where.not('allocator.id' => nil).group('allocator.id').count
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
      states = [{ id: "unassigned",
                  title: "Unassigned",
                  count: collection.state("unassigned").count },
                { id: "without-client",
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
            when "created" then "prefix.created"
            else "prefix.created DESC"
            end

    @prefixes = collection.order(order).page(page[:number]).per(page[:size])

    options = {}
    options[:meta] = {
      total: total,
      "totalPages" => @prefixes.total_pages,
      page: page[:number].to_i,
      states: states,
      providers: providers,
      years: years
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @provider_prefixes.blank? ? nil : request.base_url + "/prefixes?" + {
        query: params[:query],
        "provider-id" => params[:provider_id],
        "client_id" => params[:client_id],
        year: params[:year],
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: PrefixSerializer.new(@prefixes, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: PrefixSerializer.new(@prefix, options).serialized_json, status: :ok
  end

  def create
    @prefix = Prefix.new(safe_params)
    authorize! :create, @prefix

    if @prefix.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: PrefixSerializer.new(@prefix, options).serialized_json, status: :created, location: @prefix
    else
      logger.error @prefix.errors.inspect
      render json: serialize_errors(@prefix.errors), status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, DELETE, OPTIONS"
    render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
  end

  def totals
    return [] unless params[:client_id].present?

    page = { size: 0, number: 1}
    response = Doi.query(nil, client_id: params[:client_id], state: "findable,registered", page: page, totals_agg: "prefix")
    registrant = prefixes_totals(response.response.aggregations.prefixes_totals.buckets)
    
    render json: registrant, status: :ok
  end

  def destroy
    @prefix.destroy
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:clients, :providers]
    else
      # always include because Ember pagination doesn't (yet) understand include parameter
      @include = [:clients, :providers]
    end
  end

  private

  def set_prefix
    @prefix = Prefix.where(prefix: params[:id]).first

    # fallback to call handle server, i.e. for prefixes not from DataCite
    @prefix = Handle.where(id: params[:id]) unless @prefix.present? ||  Rails.env.test?
    fail ActiveRecord::RecordNotFound unless @prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :created],
              keys: { id: :prefix }
    )
  end
end
