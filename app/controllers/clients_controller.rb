class ClientsController < ApplicationController
  before_action :set_client, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :except => [:index, :show, :set_test_prefix]

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.raw" => { order: 'asc' }}
           when "-name" then { "name.raw" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { "name.raw" => { order: 'asc' }}
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
      response = Client.find_by_id(params[:id]) 
    elsif params[:ids].present?
      response = Client.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Client.query(params[:query], year: params[:year], provider_id: params[:provider_id], page: page, sort: sort)
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
    years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
    providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil

    @clients = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      "total-pages" => total_pages,
      page: page[:number],
      years: years,
      providers: providers
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @clients.blank? ? nil : request.base_url + "/clients?" + {
        query: params[:query],
        "provider-id" => params[:provider_id],
        year: params[:year],
        "page[number]" => page[:number] + 1,
        "page[size]" => page[:size],
        sort: params[:sort] }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true

    render json: ClientSerializer.new(@clients, options).serialized_json, status: :ok
  end

  def show
    options = {}
    options[:meta] = { dois: @client.cached_doi_count }
    options[:include] = @include
    options[:is_collection] = false

    render json: ClientSerializer.new(@client, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    @client = Client.new(safe_params)
    authorize! :create, @client

    if @client.save
      options = {}
      options[:is_collection] = false
  
      render json: ClientSerializer.new(@client, options).serialized_json, status: :created
    else
      logger.warn @client.errors.inspect
      render json: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  def update
    logger = Logger.new(STDOUT)
    if @client.update_attributes(safe_params)
      options = {}
      options[:meta] = { dois: @client.cached_doi_count }
      options[:is_collection] = false
  
      render json: ClientSerializer.new(@client, options).serialized_json, status: :ok
    else
      logger.warn @client.errors.inspect
      render json: serialize(@client.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a client with dois or prefixes can't be deleted
  def destroy
    logger = Logger.new(STDOUT)
    if @client.dois.present?
      message = "Can't delete client that has DOIs."
      status = 400
      logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @client.update_attributes(is_active: "\x00", deleted_at: Time.zone.now)
      @client.remove_users(id: "client_id", jwt: current_user.jwt) unless Rails.env.test?
      head :no_content
    else
      logger.warn @client.errors.inspect
      render json: serialize(@client.errors), status: :unprocessable_entity
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
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:provider, :repository]
    else
      @include = [:provider, :repository]
    end
  end

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
