require 'uri'

class DoisController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show, :destroy, :get_url]
  before_action :set_include, only: [:index, :show, :create, :update]
  before_bugsnag_notify :add_metadata_to_bugsnag

  def index
    authorize! :read, Doi

    if Rails.env.production? && (params[:client_id].present? || params[:provider_id].present? || params[:id].present?)
      # don't use elasticsearch

      # support nested routes
      if params[:client_id].present?
        client = Client.where('datacentre.symbol = ?', params[:client_id]).first
        collection = client.present? ? client.dois : Doi.none
        total = client.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
      elsif params[:provider_id].present? && params[:provider_id] != "admin"
        provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
        collection = provider.present? ? Doi.joins(:client).where("datacentre.allocator = ?", provider.id) : Doi.none
        total = provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
      elsif params[:id].present?
        collection = Doi.where(doi: params[:id])
        total = collection.all.size
      else
        provider = Provider.unscoped.where('allocator.symbol = ?', "ADMIN").first
        total = provider.present? ? provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i } : 0
        collection = Doi
      end

      if params[:query].present?
        collection = Doi.q(params[:query])
        total = collection.all.size
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
      total_pages = (total.to_f / page[:size]).ceil

      order = case params[:sort]
              when "name" then "dataset.doi"
              when "-name" then "dataset.doi DESC"
              when "created" then "dataset.created"
              else "dataset.created DESC"
              end

      @dois = collection.order(order).page(page[:number]).per(page[:size]).without_count

      options = {}
      options[:meta] = {
        total: total,
        "total-pages" => total_pages,
        page: page[:number].to_i
      }.compact

      options[:links] = {
        self: request.original_url,
        next: @dois.blank? ? nil : request.base_url + "/dois?" + {
          query: params[:query],
          "provider-id" => params[:provider_id],
          "client-id" => params[:client_id],
          "page[number]" => page[:number] + 1,
          "page[size]" => page[:size],
          sort: params[:sort] }.compact.to_query
        }.compact
      options[:include] = @include
      options[:is_collection] = true

      render json: DoiSerializer.new(@dois, options).serialized_json, status: :ok
    else
      sort = case params[:sort]
            when "name" then { "doi" => { order: 'asc' }}
            when "-name" then { "doi" => { order: 'desc' }}
            when "created" then { created: { order: 'asc' }}
            when "-created" then { created: { order: 'desc' }}
            when "relevance" then { "_score": { "order": "desc" }}
            else { updated: { order: 'desc' }}
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
        response = Doi.find_by_id(params[:id])
      elsif params[:ids].present?
        response = Doi.find_by_ids(params[:ids], page: page, sort: sort)
      else
        response = Doi.query(params[:query],
                            state: params[:state],
                            year: params[:year],
                            created: params[:created],
                            provider_id: params[:provider_id],
                            client_id: params[:client_id],
                            prefix: params[:prefix],
                            person_id: params[:person_id],
                            resource_type_id: camelize_str(params[:resource_type_id]),
                            schema_version: params[:schema_version],
                            source: params[:source],
                            page: page,
                            sort: sort)
      end

      total = response.results.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

      states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
      resource_types = total > 0 ? facet_by_resource_type(response.response.aggregations.resource_types.buckets) : nil
      years = total > 0 ? facet_by_year(response.response.aggregations.years.buckets) : nil
      created = total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
      providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil
      clients = total > 0 ? facet_by_client(response.response.aggregations.clients.buckets) : nil
      prefixes = total > 0 ? facet_by_key(response.response.aggregations.prefixes.buckets) : nil
      schema_versions = total > 0 ? facet_by_schema(response.response.aggregations.schema_versions.buckets) : nil
      sources = total > 0 ? facet_by_key(response.response.aggregations.sources.buckets) : nil

      @dois = response.results.results

      options = {}
      options[:meta] = {
        total: total,
        "total-pages" => total_pages,
        page: page[:number],
        states: states,
        resource_types: resource_types,
        years: years,
        created: created,
        providers: providers,
        clients: clients,
        prefixes: prefixes,
        schema_versions: schema_versions,
        sources: sources
      }.compact

      options[:links] = {
        self: request.original_url,
        next: @dois.blank? ? nil : request.base_url + "/dois?" + {
          query: params[:query],
          "provider-id" => params[:provider_id],
          "client-id" => params[:client_id],
          year: params[:year],
          "page[cursor]" => Array.wrap(@dois.last[:sort]).first,
          "page[size]" => params.dig(:page, :size) }.compact.to_query
        }.compact
      options[:include] = @include
      options[:is_collection] = true

      render json: DoiSerializer.new(@dois, options).serialized_json, status: :ok
    end
  end

  def show
    authorize! :read, @doi

    options = {}
    options[:include] = @include
    options[:is_collection] = false

    render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
  end

  def validate
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect
    @doi = Doi.new(safe_params)
    authorize! :create, @doi

    if @doi.errors.present?
      logger.info @doi.errors.inspect
      render json: serialize(@doi.errors), status: :ok
    elsif @doi.validation_errors?
      logger.info @doi.validation_errors.inspect
      render json: serialize(@doi.validation_errors), status: :ok
    else
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
    end
  end

  def create
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect
    @doi = Doi.new(safe_params)
    authorize! :create, @doi

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    if safe_params[:xml] && safe_params[:event] && @doi.validation_errors?
      logger.error @doi.validation_errors.inspect
      render json: serialize(@doi.validation_errors), status: :unprocessable_entity
    elsif @doi.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render json: DoiSerializer.new(@doi, options).serialized_json, status: :created, location: @doi
    else
      logger.warn @doi.errors.inspect
      render json: serialize(@doi.errors), include: @include, status: :unprocessable_entity
    end
  end

  def update
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect
    @doi = Doi.where(doi: params[:id]).first
    exists = @doi.present?

    if exists
      if params[:data][:attributes][:mode] == "transfer"
        authorize! :transfer, @doi
      else
        authorize! :update, @doi
      end

      @doi.assign_attributes(safe_params.except(:doi))
    else
      doi_id = validate_doi(params[:id])
      fail ActiveRecord::RecordNotFound unless doi_id.present?

      @doi = Doi.new(safe_params.merge(doi: doi_id))

      authorize! :create, @doi
    end

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    if safe_params[:xml] && (safe_params[:event] || safe_params[:validate]) && @doi.validation_errors?
      logger.error @doi.validation_errors.inspect
      render json: serialize(@doi.validation_errors), status: :unprocessable_entity
    elsif @doi.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false

      render json: DoiSerializer.new(@doi, options).serialized_json, status: exists ? :ok : :created
    else
      logger.warn @doi.errors.inspect
      render json: serialize(@doi.errors), include: @include, status: :unprocessable_entity
    end
  end

  def destroy
    logger = Logger.new(STDOUT)
    authorize! :destroy, @doi

    if @doi.draft?
      if @doi.destroy
        head :no_content
      else
        logger.warn @doi.errors.inspect
        render json: serialize(@doi.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  def status
    doi = Doi.where(doi: params[:id]).first
    status = Doi.get_landing_page_info(doi: doi, url: params[:url])
    render json: status.to_json, status: :ok
  end

  def random
    prefix = params[:prefix].presence || "10.5072"
    doi = generate_random_doi(prefix, number: params[:number])

    render json: { doi: doi }.to_json
  end

  def set_state
    authorize! :set_state, Doi

    Doi.set_state
    render json: { message: "DOI state updated." }.to_json, status: :ok
  end

  def get_url
    authorize! :get_url, @doi

    if @doi.aasm_state == "draft"
      url = @doi.url
      head :no_content and return unless url.present?
    else
      response = @doi.get_url

      if response.status == 200
        url = response.body.dig("data", "values", 0, "data", "value")
      elsif response.status == 400 && response.body.dig("errors", 0, "title", "responseCode") == 301
        response = OpenStruct.new(status: 403, body: { "errors" => [{ "status" => 403, "title" => "SERVER NOT RESPONSIBLE FOR HANDLE" }] })
        url = nil
      else
        url = nil
      end
    end

    if url.present?
      render json: { url: url }.to_json, status: :ok
    else
      render json: response.body.to_json, status: response.status || :bad_request
    end
  end

  def get_dois
    authorize! :get_urls, Doi

    client = Client.where('datacentre.symbol = ?', current_user.uid.upcase).first
    client_prefix = client.prefixes.where.not('prefix.prefix = ?', "10.5072").first
    head :no_content and return unless client_prefix.present?

    response = Doi.get_dois(prefix: client_prefix.prefix, username: current_user.uid.upcase, password: current_user.password)
    if response.status == 200
      render json: { dois: response.body.dig("data", "handles") }.to_json, status: :ok
    elsif response.status == 204
      head :no_content
    else
      render json: serialize(response.body["errors"]), status: :bad_request
    end
  end

  def set_minted
    authorize! :set_minted, Doi
    Doi.set_minted
    render json: { message: "DOI minted timestamp added." }.to_json, status: :ok
  end

  def set_url
    authorize! :set_url, Doi
    from_date = Time.zone.now - 1.day
    Doi.set_url(from_date: from_date.strftime("%F"))

    render json: { message: "Adding missing URLs queued." }.to_json, status: :ok
  end

  def delete_test_dois
    authorize! :delete_test_dois, Doi
    Doi.delete_test_dois
    render json: { message: "Test DOIs deleted." }.to_json, status: :ok
  end

  protected

  def set_doi
    @doi = Doi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user
  end

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
      @include = @include & [:client, :resource_type]
    else
      @include = [:client, :resource_type]
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?

    attributes = [
      :doi,
      "confirm-doi",
      :identifier,
      :url, :title,
      :publisher,
      :published,
      :created,
      :prefix,
      :suffix,
      "resource-type-subtype",
      "last-landing-page",
      "last-landing-page-status",
      "last-landing-page-status-check",
      {
        "last-landing-page-status-result" => [
          "error",
          "redirect-count",
          { "redirect-urls" => [] },
          "download-latency",
          "has-schema-org",
          "schema-org-id",
          "dc-identifier",
          "citation-doi",
          "body-has-pid"
        ]
      },
      "last-landing-page-content-type",
      "content-url",
      "content-size",
      "content-format",
      :description,
      :license,
      :xml,
      :validate,
      :source,
      :version,
      "metadata-version",
      "schema-version",
      :state, "is-active",
      :reason,
      :registered,
      :updated,
      :mode,
      :event,
      :regenerate,
      :client,
      "resource_type",
      author: [:type, :id, :name, "given-name", "family-name", "givenName", "familyName"]
    ]

    relationships = [
      { client: [data: [:type, :id]] },
      { provider: [data: [:type, :id]] },
      { "resource-type" => [:data, data: [:type, :id]] }
    ]

    p = params.require(:data).permit(:type, :id, attributes: attributes, relationships: relationships)
    p = p.fetch("attributes").merge(client_id: p.dig("relationships", "client", "data", "id"), resource_type_general: camelize_str(p.dig("relationships", "resource-type", "data", "id")))
    p.merge(
      additional_type: p["resource-type-subtype"],
      schema_version: p["schema-version"],
      last_landing_page: p["last-landing-page"],
      last_landing_page_status: p["last-landing-page-status"],
      last_landing_page_status_check: p["last-landing-page-status-check"],
      last_landing_page_status_result: p["last-landing-page-status-result"],
      last_landing_page_content_type: p["last-landing-page-content-type"]
    ).except(
      "confirm-doi", :identifier, :prefix, :suffix, "resource-type-subtype",
      "metadata-version", "schema-version", :state, :mode, "is-active",
      :created, :registered, :updated, "last-landing-page",
      "last-landing-page-status", "last-landing-page-status-check",
      "last-landing-page-status-result", "last-landing-page-content-type")
  end

  def underscore_str(str)
    return str unless str.present?

    str.underscore
  end

  def camelize_str(str)
    return str unless str.present?

    str.underscore.camelize
  end

  def add_metadata_to_bugsnag(report)
    return nil unless params.dig(:data, :attributes, :xml).present?

    report.add_tab(:metadata, {
      metadata: Base64.decode64(params.dig(:data, :attributes, :xml))
    })
  end
end
