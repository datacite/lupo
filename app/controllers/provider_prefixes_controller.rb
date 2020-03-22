class ProviderPrefixesController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :set_provider_prefix, only: [:show, :update, :destroy]
  before_action :set_include
  authorize_resource :except => [:index, :show]
  around_action :skip_bullet, only: [:index], if: -> { defined?(Bullet) }

  def index
    sort = case params[:sort]
           when "name" then { "prefix_id" => { order: 'asc', unmapped_type: "keyword" }}
           when "-name" then { "prefix_id" => { order: 'desc', unmapped_type: "keyword" }}
           when "created" then { created_at: { order: 'asc' }}
           when "-created" then { created_at: { order: 'desc' }}
           else { created_at: { order: 'desc' }}
           end

    page = page_from_params(params)

    if params[:id].present?
      response = ProviderPrefix.find_by_id(params[:id]) 
    else
      response = ProviderPrefix.query(params[:query],
                                      prefix_id: params[:prefix_id],
                                      consortium_id: params[:consortium_id],
                                      provider_id: params[:provider_id],
                                      consortium_organization_id: params[:consortium_organization_id],
                                      state: params[:state],
                                      year: params[:year],
                                      page: page, 
                                      sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size].positive? ? (total.to_f / page[:size]).ceil : 0
      years = total.positive? ? facet_by_year(response.response.aggregations.years.buckets) : nil
      states = total.positive? ? facet_by_key(response.response.aggregations.states.buckets) : nil
      providers = total.positive? ? facet_by_provider(response.response.aggregations.providers.buckets) : nil

      provider_prefixes = response.results

      options = {}
      options[:meta] = {
        total: total,
        "totalPages" => total_pages,
        page: page[:number],
        years: years,
        states: states,
        providers: providers,
      }.compact

      options[:links] = {
        self: request.original_url,
        next: provider_prefixes.blank? ? nil : request.base_url + "/provider_prefixes?" + {
        query: params[:query],
        prefix: params[:prefix],
        year: params[:year],
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
      options[:include] = @include
      options[:is_collection] = true

      render json: ProviderPrefixSerializer.new(provider_prefixes, options).serialized_json, status: :ok
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

    render json: ProviderPrefixSerializer.new(@provider_prefix, options).serialized_json, status: :ok
  end

  def create
    @provider_prefix = ProviderPrefix.new(safe_params)
    authorize! :create, @provider_prefix

    if @provider_prefix.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render json: ProviderPrefixSerializer.new(@provider_prefix, options).serialized_json, status: :created
    else
      Rails.logger.error @provider_prefix.errors.inspect
      render json: serialize_errors(@provider_prefix.errors), status: :unprocessable_entity
    end
  end

  def update
    response.headers["Allow"] = "HEAD, GET, POST, DELETE, OPTIONS"
    render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
  end

  def destroy
    message = "Provider prefix #{@provider_prefix.uid} deleted."
    if @provider_prefix.destroy
      Rails.logger.warn message
      head :no_content
    else
      Rails.logger.error @provider_prefix.errors.inspect
      render json: serialize_errors(@provider_prefix.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:provider, :prefix, :clients, :client_prefixes]
    else
      @include = []
    end
  end

  private

  def set_provider_prefix
    @provider_prefix = ProviderPrefix.where(uid: params[:id]).first
    fail ActiveRecord::RecordNotFound if @provider_prefix.blank?
  end

  def safe_params
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:id, :provider, :prefix]
    )
  end
end
