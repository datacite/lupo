class ProvidersController < ApplicationController
  before_action :set_provider, only: [:show, :update, :destroy]
  before_action :set_include, :authenticate_user!
  load_and_authorize_resource :except => [:index, :show, :set_test_prefix]

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.raw" => { order: 'asc' }}
           when "-name" then { "name.raw" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { updated: { "order": "asc" }}
           end

    page = params[:page] || {}
    if page[:size].present? 
      page[:size] = [page[:size].to_i, 1000].min
      max_number = page[:size] > 0 ? 10000/page[:size] : 1
    else
      page[:size] = 25
      max_number = 10000/page[:size]
    end
    page[:number] = page[:number].to_i > 0 ? [page[:number].to_i, max_number].min : 1

    if params[:id].present?
      response = Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Provider.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Provider.query(params[:query], year: params[:year], page: page, sort: sort)
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil

    @providers = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      "total-pages" => total_pages,
      page: page[:number],
      years: years
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @providers.blank? ? nil : request.base_url + "/providers?" + {
        query: params[:query],
        year: params[:year],
        "page[number]" => params.dig(:page, :number),
        "page[size]" => params.dig(:page, :size),
        sort: sort }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: ProviderSerializer.new(@providers, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:meta] = { 
      providers: @provider.provider_count,
      clients: @provider.client_count,
      dois: @provider.cached_doi_count }.compact
    options[:include] = @include
    options[:is_collection] = false

    render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
  end

  # POST /providers
  def create
    @provider = Provider.new(safe_params)
    authorize! :create, @provider

    if @provider.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      Rails.logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /providers/1
  def update
    Rails.logger.debug safe_params.inspect
    if @provider.update_attributes(safe_params)
      options = {}
      options[:meta] = { 
        providers: @provider.provider_count,
        clients: @provider.client_count,
        dois: @provider.cached_doi_count }.compact
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      Rails.logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a provider with clients or prefixes can't be deleted
  def destroy
    if @provider.client_count.present?
      message = "Can't delete provider that has clients."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @provider.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      @provider.remove_users(id: "provider_id", jwt: current_user.jwt) unless Rails.env.test?
      head :no_content
    else
      Rails.logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  def set_test_prefix
    authorize! :update, Provider
    Provider.find_each do |p|
      p.send(:set_test_prefix)
      p.save
    end
    render json: { message: "Test prefix added." }.to_json, status: :ok
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_ADMIN')").where(deleted_at: nil).where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end

  private

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include
    else
      @include = nil
    end
  end

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:name, :symbol, :description, :website, :joined, "institution-type", :phone, "contact-name", "contact-email", "is_active", "password-input", :country],
              keys: { "institution-type" => :institution_type, "contact-name" => :contact_name, "contact-email" => :contact_email, :country => :country_code, "is-active" => :is_active, "password-input" => :password_input }
    )
  end
end
