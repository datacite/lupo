class RepositoriesController < ApplicationController
  include ActionController::MimeResponds
  include Countable

  before_action :set_repository, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_include
  load_and_authorize_resource :client, parent: false, except: [:index, :show, :create, :totals, :random, :stats]
  around_action :skip_bullet, only: [:index], if: -> { defined?(Bullet) }
  
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
      response = Client.find_by_id(params[:id])
    elsif params[:ids].present?
      response = Client.find_by_id(params[:ids], page: page, sort: sort)
    else
      response = Client.query(params[:query],
                              year: params[:year],
                              from_date: params[:from_date],
                              until_date: params[:until_date],
                              provider_id: params[:provider_id],
                              consortium_id: params[:consortium_id],
                              re3data_id: params[:re3data_id],
                              opendoar_id: params[:opendoar_id],
                              software: params[:software],
                              certificate: params[:certificate],
                              repository_type: params[:repository_type],
                              client_type: params[:client_type],
                              page: page,
                              sort: sort)
    end

    begin
      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0
      years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
      providers = total > 0 ? facet_by_combined_key(response.response.aggregations.providers.buckets) : nil
      software = total > 0 ? facet_by_software(response.response.aggregations.software.buckets) : nil
      certificates = total > 0 ? facet_by_key(response.response.aggregations.certificates.buckets) : nil
      client_types = total > 0 ? facet_by_key(response.response.aggregations.client_types.buckets) : nil
      repository_types = total > 0 ? facet_by_key(response.response.aggregations.repository_types.buckets) : nil

      respond_to do |format|
        format.json do
          options = {}
          options[:meta] = {
            total: total,
            "totalPages" => total_pages,
            page: page[:number],
            years: years,
            providers: providers,
            "clientTypes" => client_types,
            "repositoryTypes" => repository_types,
            certificates: certificates,
            software: software
          }.compact

          options[:links] = {
            self: request.original_url,
            next: response.results.blank? ? nil : request.base_url + "/repositories?" + {
              query: params[:query],
              "provider-id" => params[:provider_id],
              software: params[:software],
              certificate: params[:certificate],
              "client-type" => params[:client_type],
              "repository-type" => params[:repository_type],
              year: params[:year],
              "page[number]" => page[:number] + 1,
              "page[size]" => page[:size],
              sort: params[:sort] }.compact.to_query
            }.compact
          options[:include] = @include
          options[:is_collection] = true
          options[:params] = { current_ability: current_ability }

          fields = fields_from_params(params)
          if fields
            render json: RepositorySerializer.new(response.results, options.merge(fields: fields)).serialized_json, status: :ok
          else
            render json: RepositorySerializer.new(response.results, options).serialized_json, status: :ok
          end
        end
        header = %w(
          accountName
          fabricaAccountId
          parentFabricaAccountId
          salesForceId
          parentSalesForceId
          isActive
          created
          updated
          re3data_id
          client_type
          alternate_name
          description
          url
          software
          system_email)
        format.csv { render request.format.to_sym => response.records.to_a, header: header }
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Raven.capture_exception(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    repository = Client.where(symbol: params[:id]).where(deleted_at: nil).first
    fail ActiveRecord::RecordNotFound unless repository.present?

    options = {}
    options[:meta] = {
      "doiCount" => doi_count(client_id: params[:id]).reduce(0) do |sum, item|
        sum += item["count"]
        sum
      end,
      "prefixCount" => Array.wrap(repository.prefix_ids).length,
    }.compact
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = { current_ability: current_ability }

    render json: RepositorySerializer.new(repository, options).serialized_json, status: :ok
  end

  def create
    @client = Client.new(safe_params)

    authorize! :create, @client

    if @client.save
      options = {}
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability }

      render json: RepositorySerializer.new(@client, options).serialized_json, status: :created
    else
      Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors), status: :unprocessable_entity
    end
  end

  def update
    if @client.update_attributes(safe_params)
      options = {}
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability }

      render json: RepositorySerializer.new(@client, options).serialized_json, status: :ok
    else
      Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors), status: :unprocessable_entity
    end
  end

  # don't delete, but set deleted_at timestamp
  # a repository with dois or prefixes can't be deleted
  def destroy
    if @client.dois.present?
      message = "Can't delete repository that has DOIs."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif @client.update_attributes(is_active: nil, deleted_at: Time.zone.now)
      @client.send_delete_email unless Rails.env.test?
      head :no_content
    else
      Rails.logger.error @client.errors.inspect
      render json: serialize_errors(@client.errors), status: :unprocessable_entity
    end
  end

  def random
    symbol = generate_random_repository_symbol
    render json: { symbol: symbol }.to_json
  end

  def totals
    page = { size: 0, number: 1 }

    state =  current_user.present? && current_user.is_admin_or_staff? && params[:state].present? ? params[:state] : "registered,findable"
    response = Doi.query(nil, provider_id: params[:provider_id], state: state, page: page, totals_agg: "client")
    registrant = response.results.total.positive? ? clients_totals(response.response.aggregations.clients_totals.buckets) : []

    render json: registrant, status: :ok
  end

  def stats
    meta = {
      dois: doi_count(client_id: params[:id]),
      "resourceTypes" => resource_type_count(client_id: params[:id]),
      # citations: citation_count(client_id: params[:id]),
      # views: view_count(client_id: params[:id]),
      # downloads: download_count(client_id: params[:id]),
    }.compact

    render json: meta, status: :ok
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:provider]
    else
      @include = []
    end
  end

  def set_repository
    @client = Client.where(symbol: params[:id]).where(deleted_at: nil).first
    fail ActiveRecord::RecordNotFound if @client.blank?
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" if params[:data].blank?

    ActiveModelSerializers::Deserialization.jsonapi_parse!(
      params, only: [:symbol, :name, "systemEmail", :domains, :provider, :url, "globusUuid", "repositoryType", { "repositoryType" => [] }, :description, :language, { language: [] }, "alternateName", :software, "targetId", "isActive", "passwordInput", "clientType", :re3data, :opendoar, :issn, { issn: [:issnl, :electronic, :print] }, :certificate, { certificate: [] }, "serviceContact", { "serviceContact": [:email, "givenName", "familyName"] }, "salesforceId"],
              keys: { "systemEmail" => :system_email, "salesforceId" => :salesforce_id, "globusUuid" => :globus_uuid, "targetId" => :target_id, "isActive" => :is_active, "passwordInput" => :password_input, "clientType" => :client_type, "alternateName" => :alternate_name, "repositoryType" => :repository_type, "serviceContact" => :service_contact }
    )
  end
end
