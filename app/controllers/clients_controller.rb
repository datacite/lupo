class ClientsController < ApplicationController
  before_action :set_client, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show, :set_test_prefix]

  def index
    page = (params.dig(:page, :number) || 1).to_i
    size = (params.dig(:page, :size) || 25).to_i
    from = (page - 1) * size

    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.keyword" => { order: 'asc' }}
           when "-name" then { "name.keyword" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { "name.keyword": { "order": "asc" }}
           end

    if params[:id].present?
      response = Client.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Client.find_by_ids(params[:ids], from: from, size: size, sort: sort)
    else
      response = Client.query(params[:query], year: params[:year], provider_id: params[:provider_id], from: from, size: size, sort: sort)
    end

    total = response.results.total
    total_pages = (total.to_f / size).ceil
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
    providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil

    #@clients = Kaminari.paginate_array(response.results, total_count: total).page(page).per(size)
    @clients = response.page(page).per(size).records

    meta = {
      total: total,
      total_pages: total_pages,
      page: page,
      years: years,
      providers: providers
    }.compact

    render jsonapi: @clients, meta: meta, include: @include
  end

  # GET /clients/1
  def show
    meta = { dois: @client.cached_doi_count }

    render jsonapi: @client, meta: meta, include: @include
  end

  # POST /clients
  def create
    @client = Client.new(safe_params)
    authorize! :create, @client

    if @client.save
      render jsonapi: @client, status: :created
    else
      Rails.logger.warn @client.errors.inspect
      render jsonapi: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clients/1
  def update
    if @client.update_attributes(safe_params)
      render jsonapi: @client
    else
      Rails.logger.warn @client.errors.inspect
      render json: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a client with dois or prefixes can't be deleted
  def destroy
    if @client.dois.present?
      message = "Can't delete client that has DOIs."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @client.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      @client.remove_users(id: "client_id", jwt: current_user.jwt) unless Rails.env.test?
      head :no_content
    else
      Rails.logger.warn @client.errors.inspect
      render jsonapi: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  def set_test_prefix
    authorize! :update, Client
    Client.find_each do |c|
      c.send(:set_test_prefix)
      c.save
    end
    render json: { message: "Test prefix added." }.to_json, status: :ok
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore }.join(",")
      @include = [@include]
    else
      @include = ["provider", "repository"]
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_client
    # params[:id] = params[:id][/.+?(?=\/)/]
    @client = Client.where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @client.present?
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:symbol, :name, "contact-name", "contact-email", :domains, :provider, :url, :repository, "target-id", "is-active", "password-input"],
              keys: { "contact-name" => :contact_name, "contact-email" => :contact_email, "target-id" => :target_id, "is-active" => :is_active, "password-input" => :password_input }
    )
  end
end
