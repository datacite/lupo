require 'benchmark'

class ProvidersController < ApplicationController
  include ActionController::MimeResponds
  include Countable

  before_action :set_provider, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  load_and_authorize_resource :except => [:index, :show, :totals]

  def index
    sort = case params[:sort]
           when "relevance" then { "_score" => { order: 'desc' }}
           when "name" then { "name.raw" => { order: 'asc' }}
           when "-name" then { "name.raw" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           else { "name.raw" => { order: 'asc' }}
           end

    page = page_from_params(params)

    if params[:id].present?
      response = Provider.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Provider.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = Provider.query(params[:query], year: params[:year], region: params[:region], organization_type: params[:organization_type], focus_area: params[:focus_area], page: page, sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
      regions = total > 0 ? facet_by_region(response.response.aggregations.regions.buckets) : nil
      organization_types = total > 0 ? facet_by_key(response.response.aggregations.organization_types.buckets) : nil
      focus_areas = total > 0 ? facet_by_key(response.response.aggregations.focus_areas.buckets) : nil

      @providers = response.results
      respond_to do |format|
        format.json do
            options = {}
            options[:meta] = {
              total: total,
              "totalPages" => total_pages,
              page: page[:number],
              years: years,
              regions: regions,
              "organizationTypes" => organization_types,
              "focusAreas" => focus_areas
            }.compact

            options[:links] = {
              self: request.original_url,
              next: @providers.blank? ? nil : request.base_url + "/providers?" + {
                query: params[:query],
                year: params[:year],
                region: params[:region],
                "organization_type" => params[:organization_type],
                "focus-area" => params[:focus_area],
                fields: params[:fields],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: sort }.compact.to_query
              }.compact
            options[:include] = @include
            options[:is_collection] = true

            render json: ProviderSerializer.new(@providers, options).serialized_json, status: :ok
        end
        header = %w(name provider_id year contact_name contact_address is_active description website phone region country_code logo_url  focus_area organisation_type memmber_type role_name password joined created updated deleted_at)
        format.csv { render request.format.to_sym => response.records.to_a, header: header }
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    options = {}
    options[:meta] = { 
      providers: provider_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
      clients: client_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
      dois: doi_count(provider_id: params[:id] == "admin" ? nil : params[:id]) }.compact
    options[:include] = @include
    options[:is_collection] = false

    render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    @provider = Provider.new(safe_params)
    authorize! :create, @provider

    if @provider.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  def update
    logger = Logger.new(STDOUT)
    # logger.debug safe_params.inspect
    if @provider.update_attributes(safe_params)
      options = {}
      options[:meta] = { 
        providers: provider_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
        clients: client_count(provider_id: params[:id] == "admin" ? nil : params[:id]),
        dois: doi_count(provider_id: params[:id] == "admin" ? nil : params[:id]) }.compact
      options[:include] = @include
      options[:is_collection] = false
  
      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  def totals
    logger = Logger.new(STDOUT)

    page = { size: 0, number: 1}
    response = nil
    logger.info "[Benchmark] providers totals " + Benchmark.ms {
      response = Doi.query("", state: params[:state] || "", page: page, totals_agg: true)
    }.to_s + " ms"
    total = response.results.total

    registrant = nil
    logger.info "[Benchmark] providers providers_totals " + Benchmark.ms {
      registrant = total > 0 ? providers_totals(response.response.aggregations.providers_totals.buckets) : nil
    }.to_s + " ms"
    logger.info "[Benchmark] providers render " + Benchmark.ms {
      render json: registrant, status: :ok
    }.to_s + " ms"
  end


  # don't delete, but set deleted_at timestamp
  # a provider with active clients or with prefixes can't be deleted
  def destroy
    logger = Logger.new(STDOUT)
    if active_client_count(provider_id: @provider.symbol) > 0
      message = "Can't delete provider that has active clients."
      status = 400
      logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @provider.update_attributes(is_active: nil, deleted_at: Time.zone.now)
      @provider.send_delete_email unless Rails.env.test?
      head :no_content
    else
      logger.warn @provider.errors.inspect
      render json: serialize(@provider.errors), status: :unprocessable_entity
    end
  end

  protected

  # Use callbacks to share common setup or constraints between actions.
  def set_provider
    @provider = Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_ADMIN')").where(deleted_at: nil).where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    attributes = [
      :name, :symbol, :description, :website, :joined, :phone, :country, "organizationType",  "focusArea", "contactName", "contactEmail", :country, "isActive", "passwordInput", "twitterHandle", "rorId", :created, "hasPassword", "keepPassword", "logoUrl", :updated, :region, "billingInformation": ["postCode", :state, :city, :address]
    ]
    params.require(:data).permit(:type, attributes: attributes)
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:name, :symbol, :description, :website, :joined, "organizationType", "focusArea", :phone, "contactName", "contactEmail", "isActive", "passwordInput", :country, "billingInformation",{ "billingInformation": ["postCode", :state, :city, :address]}, "rorId", "twitterHandle" ],
              keys: { "organizationType" => :organization_type, "focusArea" => :focus_area, "contactName" => :contact_name, "contactEmail" => :contact_email, :country => :country_code, "isActive" => :is_active, "passwordInput" => :password_input,  "billingInformation" => :billing_information , "postCode" => :post_code, "rorId" => :ror_id, "twitterHandle" =>:twitter_handle  }
    )
  end
end
