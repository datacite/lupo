class PrefixesController < ApplicationController
  before_action :set_prefix, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show, :totals]
  around_action :skip_bullet, only: [:index], if: -> { defined?(Bullet) }
  
  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "uid" => { order: 'asc' }}
           when "-name" then { "uid" => { order: 'desc' }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           else { "uid" => { order: 'asc' }}
           end

    page = page_from_params(params)

    if params[:id].present?
      response = Prefix.find_by_id(params[:id]) 
    else
      response = Prefix.query(params[:query], 
        prefix: params[:prefix],
        year: params[:year],
        state: params[:state],
        provider_id: params[:provider_id],
        client_id: params[:client_id],
        page: page, 
        sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size].positive? ? (total.to_f / page[:size]).ceil : 0
      years = total.positive? ? facet_by_year(response.response.aggregations.years.buckets) : nil
      states = total.positive? ? facet_by_key(response.response.aggregations.states.buckets) : nil
      providers = total.positive? ? facet_by_provider(response.response.aggregations.providers.buckets) : nil
      clients = total.positive? ? facet_by_client(response.response.aggregations.clients.buckets) : nil
      
      prefixes = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
        years: years,
        states: states,
        providers: providers,
        clients: clients
      }.compact

      options[:links] = {
        self: request.original_url,
        next: prefixes.blank? ? nil : request.base_url + "/prefixes?" + {
          query: params[:query],
          prefix: params[:prefix],
          year: params[:year],
          "page[number]" => page[:number] + 1,
          "page[size]" => page[:size],
          sort: params[:sort] }.compact.to_query
        }.compact
      options[:include] = @include
      options[:is_collection] = true

      render json: PrefixSerializer.new(prefixes, options).serialized_json, status: :ok
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
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
    @prefix = Prefix.where(uid: params[:id]).first

    # fallback to call handle server, i.e. for prefixes not from DataCite
    @prefix = Handle.where(id: params[:id]) unless @prefix.present? ||  Rails.env.test?
    fail ActiveRecord::RecordNotFound unless @prefix.present?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :created_at],
              keys: { id: :uid }
    )
  end
end
