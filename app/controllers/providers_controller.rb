require 'benchmark'

class ProvidersController < ApplicationController
  include ActionController::MimeResponds
  include Countable

  prepend_before_action :authenticate_user!
  before_action :set_provider, only: [:show, :update, :destroy]
  before_action :set_include
  load_and_authorize_resource :except => [:totals]

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
      response = Provider.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = Provider.query(params[:query],
        exclude_registration_agencies: params[:exclude_registration_agencies],
        year: params[:year], 
        region: params[:region], 
        consortium_id: params[:consortium_id], 
        member_type: params[:member_type], 
        organization_type: params[:organization_type], 
        focus_area: params[:focus_area], 
        non_profit_status: params[:non_profit_status],
        page: page, 
        sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
      regions = total > 0 ? facet_by_region(response.response.aggregations.regions.buckets) : nil
      member_types = total > 0 ? facet_by_key(response.response.aggregations.member_types.buckets) : nil
      organization_types = total > 0 ? facet_by_key(response.response.aggregations.organization_types.buckets) : nil
      focus_areas = total > 0 ? facet_by_key(response.response.aggregations.focus_areas.buckets) : nil
      non_profit_statuses = total > 0 ? facet_by_key(response.response.aggregations.non_profit_statuses.buckets) : nil

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
              "memberTypes" => member_types,
              "organizationTypes" => organization_types,
              "focusAreas" => focus_areas,
              "nonProfitStatuses" => non_profit_statuses
            }.compact

            options[:links] = {
              self: request.original_url,
              next: @providers.blank? ? nil : request.base_url + "/providers?" + {
                query: params[:query],
                year: params[:year],
                region: params[:region],
                "member_type" => params[:member_type],
                "organization_type" => params[:organization_type],
                "focus-area" => params[:focus_area],
                "non-profit-status" => params[:non_profit_status],
                "page[number]" => page[:number] + 1,
                "page[size]" => page[:size],
                sort: sort }.compact.to_query
              }.compact
            options[:include] = @include
            options[:is_collection] = true
            options[:params] = { current_ability: current_ability }

            fields = fields_from_params(params)
            if fields
              render json: ProviderSerializer.new(@providers, options.merge(fields: fields)).serialized_json, status: :ok
            else
              render json: ProviderSerializer.new(@providers, options).serialized_json, status: :ok
            end
        end
        header = %w(
          accountName
          fabricaAccountId
          year
          is_active
          accountDescription
          accountWebsite
          region
          country
          logo_url
          focusArea
          organisation_type
          accountType
          generalContactEmail
          groupEmail
          technicalContactEmail
          technicalContactGivenName
          technicalContactFamilyName
          secondaryTechnicalContactEmail
          secondaryTechnicalContactGivenName
          secondaryTechnicalContactFamilyName
          serviceContactEmail
          serviceContactGivenName
          serviceContactFamilyName
          secondaryServiceContactEmail
          secondaryServiceContactGivenName
          secondaryServiceContactFamilyName
          votingContactEmail
          votingContactGivenName
          votingContactFamilyName
          billingStreet
          billingPostalCode
          billingCity
          department
          billingOrganization
          billingState
          billingCountry
          billingContactEmail
          billingContactGivenName
          billingontactFamilyName
          secondaryBillingContactEmail
          secondaryBillingContactGivenName
          secondaryBillingContactFamilyName
          twitter
          ror_id
          member_type
          joined
          created
          updated
          deleted_at)
        format.csv { render request.format.to_sym => response.records.to_a, header: header }
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    if params[:id] == "admin"
      providers = provider_count(consortium_id: nil)
      clients = client_count(provider_id: nil)
      dois = doi_count(provider_id: nil)
    elsif @provider.member_type == "consortium_member"
      providers = provider_count(consortium_id: params[:id])
      clients = client_count(consortium_id: params[:id])
      dois = doi_count(consortium_id: params[:id])
    else
      providers = nil
      clients = client_count(provider_id: params[:id])
      dois = doi_count(provider_id: params[:id])
    end

    options = {}
    options[:meta] = {
      providers: providers,
      clients: clients,
      dois: dois }.compact
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
  end

  def create
    logger = Logger.new(STDOUT)
    @provider = Provider.new(safe_params)
    authorize! :create, @provider

    if @provider.save
      if @provider.symbol == "ADMIN"
        providers = provider_count(consortium_id: nil)
        clients = client_count(provider_id: nil)
        dois = doi_count(provider_id: nil)
      elsif @provider.member_type == "consortium_member"
        providers = provider_count(consortium_id: params[:id])
        clients = client_count(consortium_id: params[:id])
        dois = doi_count(consortium_id: params[:id])
      else
        providers = nil
        clients = client_count(provider_id: params[:id])
        dois = doi_count(provider_id: params[:id])
      end

      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:meta] = {
        providers: providers,
        clients: clients,
        dois: dois }.compact
      options[:params] = { current_ability: current_ability }

      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      logger.warn @provider.errors.inspect
      render json: serialize_errors(@provider.errors), status: :unprocessable_entity
    end
  end

  def update
    logger = Logger.new(STDOUT)
    # logger.debug safe_params.inspect
    if @provider.update_attributes(safe_params)
      if params[:id] == "admin"
        providers = provider_count(consortium_id: nil)
        clients = client_count(provider_id: nil)
        dois = doi_count(provider_id: nil)
      elsif @provider.member_type == "consortium_member"
        providers = provider_count(consortium_id: params[:id])
        clients = client_count(consortium_id: params[:id])
        dois = doi_count(consortium_id: params[:id])
      else
        providers = nil
        clients = client_count(provider_id: params[:id])
        dois = doi_count(provider_id: params[:id])
      end

      options = {}
      options[:meta] = {
        providers: providers,
        clients: clients,
        dois: dois }.compact
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability }

      render json: ProviderSerializer.new(@provider, options).serialized_json, status: :ok
    else
      logger.warn @provider.errors.inspect
      render json: serialize_errors(@provider.errors), status: :unprocessable_entity
    end
  end

  def totals
    logger = Logger.new(STDOUT)

    page = { size: 0, number: 1 }
    response = nil
    bmt = Benchmark.ms {
      state =  current_user.present? && current_user.is_admin_or_staff? && params[:state].present? ? params[:state] : "registered,findable"
      response = Doi.query(nil, state: state, page: page, totals_agg: true)
    }
    
    if bmt > 10000
      logger.warn "[Benchmark Warning] providers totals " + bmt.to_s + " ms"
    else
      logger.info "[Benchmark] providers totals " + bmt.to_s + " ms"
    end

    logger.info response.results.inspect

    total = response.results.total

    registrant = nil
    bmp = Benchmark.ms {
      registrant = total > 0 ? providers_totals(response.response.aggregations.providers_totals.buckets) : nil
    }
    if bmp > 10000
      logger.warn "[Benchmark Warning] providers providers_totals " + bmp.to_s + " ms"
    else
      logger.info "[Benchmark] providers providers_totals " + bmp.to_s + " ms"
    end

    bmr = Benchmark.ms {
      render json: registrant, status: :ok
    }
    if bmr > 10000
      logger.warn "[Benchmark Warning] providers render " + bmr.to_s + " ms"
    else
      logger.info "[Benchmark] providers render " + bmr.to_s + " ms"
    end
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
      render json: serialize_errors(@provider.errors), status: :unprocessable_entity
    end
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:consortium, :consortium_organizations]
    else
      @include = []
    end
  end

  def set_provider
    @provider = Provider.unscoped.where("allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR', 'ROLE_ADMIN', 'ROLE_MEMBER', 'ROLE_REGISTRATION_AGENCY')").where(deleted_at: nil).where(symbol: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @provider.present?
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?
    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params,
      only: [
        :name, "displayName", :symbol, :description, :website, :joined, "organizationType", "focusArea", :consortium, "systemEmail", "groupEmail", "isActive", "passwordInput", :country, "billingInformation", { "billingInformation": ["postCode", :state, :city, :address, :department, :organization, :country]}, "rorId", "twitterHandle","memberType", "nonProfitStatus", "salesforceId",
      "technicalContact", { "technicalContact": [:email, "givenName", "familyName"] },
      "secondaryTechnicalContact", { "secondaryTechnicalContact": [:email, "givenName", "familyName"] },
      "secondaryBillingContact", { "secondaryBillingContact": [:email, "givenName", "familyName"] },
      "billingContact", { "billingContact": [:email, "givenName", "familyName"] },
      "serviceContact", { "serviceContact": [:email, "givenName", "familyName"] },
      "secondaryServiceContact", { "secondaryServiceContact": [:email, "givenName", "familyName"] },
      "votingContact", { "votingContact": [:email, "givenName", "familyName"] }
      ],
      keys: {
        "displayName" => :display_name,
        "organizationType" => :organization_type, "focusArea" => :focus_area, :country => :country_code, "isActive" => :is_active, "passwordInput" => :password_input,  "billingInformation" => :billing_information , "postCode" => :post_code, "rorId" => :ror_id, "twitterHandle" => :twitter_handle, "memberType" => :member_type,
        "technicalContact" => :technical_contact,
        "secondaryTechnicalContact" => :secondary_technical_contact,
        "secondaryBillingContact" => :secondary_billing_contact,
        "billingContact" => :billing_contact,
        "serviceContact" => :service_contact,
        "secondaryServiceContact" => :secondary_service_contact,
        "votingContact" => :voting_contact,
        "groupEmail" => :group_email,
        "systemEmail" => :system_email,
        "nonProfitStatus" => :non_profit_status,
        "salesforceId" => :salesforce_id
      }
    )
  end
end
