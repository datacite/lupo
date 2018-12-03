require 'uri'
require 'base64'

class DoisController < ApplicationController
  include Crosscitable

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show, :destroy, :get_url]
  before_action :set_include, only: [:index, :show, :create, :update]
  before_bugsnag_notify :add_metadata_to_bugsnag

  def index
    authorize! :read, Doi

    sort = case params[:sort]
          when "name" then { "doi" => { order: 'asc' }}
          when "-name" then { "doi" => { order: 'desc' }}
          when "created" then { created: { order: 'asc' }}
          when "-created" then { created: { order: 'desc' }}
          when "updated" then { updated: { order: 'asc' }}
          when "-updated" then { updated: { order: 'desc' }}
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
                          created: params[:created],
                          registered: params[:registered],
                          provider_id: params[:provider_id],
                          client_id: params[:client_id],
                          prefix: params[:prefix],
                          person_id: params[:person_id],
                          resource_type_id: params[:resource_type_id],
                          query_fields: params[:query_fields],
                          schema_version: params[:schema_version],
                          link_check_status: params[:link_check_status],
                          source: params[:source],
                          page: page,
                          sort: sort)
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? ([total.to_f, 10000].min / page[:size]).ceil : 0

    states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
    resource_types = total > 0 ? facet_by_resource_type(response.response.aggregations.resource_types.buckets) : nil
    created = total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
    registered = total > 0 ? facet_by_year(response.response.aggregations.registered.buckets) : nil
    providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil
    clients = total > 0 ? facet_by_client(response.response.aggregations.clients.buckets) : nil
    prefixes = total > 0 ? facet_by_key(response.response.aggregations.prefixes.buckets) : nil
    schema_versions = total > 0 ? facet_by_schema(response.response.aggregations.schema_versions.buckets) : nil
    sources = total > 0 ? facet_by_key(response.response.aggregations.sources.buckets) : nil
    link_checks = total > 0 ? facet_by_cumulative_year(response.response.aggregations.link_checks.buckets) : nil

    @dois = response.results.results

    options = {}
    options[:meta] = {
      total: total,
      "total-pages" => total_pages,
      page: page[:number],
      states: states,
      "resource-types" => resource_types,
      created: created,
      registered: registered,
      providers: providers,
      clients: clients,
      prefixes: prefixes,
      "schema-versions" => schema_versions,
      sources: sources,
      "link-checks" => link_checks
    }.compact

    options[:links] = {
      self: request.original_url,
      next: @dois.blank? ? nil : request.base_url + "/dois?" + {
        query: params[:query],
        "provider-id" => params[:provider_id],
        "client-id" => params[:client_id],
        fields: params[:fields],
        "page[cursor]" => Array.wrap(@dois.last[:sort]).first,
        "page[size]" => params.dig(:page, :size) }.compact.to_query
      }.compact
    options[:include] = @include
    options[:is_collection] = true
    options[:params] = {
      :current_ability => current_ability,
    }

    render json: DoiSerializer.new(@dois, options).serialized_json, status: :ok
  end

  def show
    authorize! :read, @doi

    options = {}
    options[:include] = @include
    options[:is_collection] = false
    options[:params] = {
      current_ability: current_ability,
      detail: true
    }

    render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
  end

  def validate
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect
    @doi = Doi.new(safe_params.merge(only_validate: true))
    
    authorize! :validate, @doi

    if @doi.valid?
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        :current_ability => current_ability,
      }

      render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
    else
      logger.info @doi.errors.messages
      render json: serialize(@doi.errors.messages), status: :ok
    end
  end

  def create
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect

    @doi = Doi.new(safe_params)

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    authorize! :new, @doi

    if @doi.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        detail: true
      }

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
      # capture username and password for reuse in the handle system
      @doi.current_user = current_user

      if params.dig(:data, :attributes, :mode) == "transfer"
        authorize! :transfer, @doi
      else
        authorize! :update, @doi
      end

      @doi.assign_attributes(safe_params.except(:doi))
    else
      doi_id = validate_doi(params[:id])
      fail ActiveRecord::RecordNotFound unless doi_id.present?

      @doi = Doi.new(safe_params.merge(doi: doi_id))
      # capture username and password for reuse in the handle system
      @doi.current_user = current_user

      authorize! :new, @doi
    end

    if @doi.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        detail: true
      }

      render json: DoiSerializer.new(@doi, options).serialized_json, status: exists ? :ok : :created
    else
      logger.warn @doi.errors.messages
      render json: serialize(@doi.errors.messages), include: @include, status: :unprocessable_entity
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
    logger = Logger.new(STDOUT)

    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?

    # default values for attributes stored as JSON
    defaults = { data: { titles: [], descriptions: [], types: {}, dates: [], rightsList: [], creators: [], contributors: [] }}

    attributes = [
      :doi,
      :confirmDoi,
      :identifier,
      :url,
      :titles,
      { titles: [:title, :titleType, :lang] },
      :publisher,
      :publicationYear,
      :created,
      :prefix,
      :suffix,
      :types,
      { types: [:resourceTypeGeneral, :resourceType, :schemaOrg, :bibtex, :citeproc, :ris] },
      :dates,
      { dates: [:date, :dateType, :dateInformation] },
      :landingPage,
      {
        landingPage: [
          :checked,
          :url,
          :status,
          :contentType,
          :error,
          :redirectCount,
          { redirectUrls: [] },
          :downloadLatency,
          :hasSchemaOrg,
          :schemaOrgId,
          { schemaOrgId: ["@type", :value, :propertyID] },
          :dcIdentifier,
          :citationDoi,
          :bodyHasPid
        ]
      },
      :contentUrl,
      :size,
      :format,
      :descriptions,
      { descriptions: [:description, :descriptionType, :lang] },
      :rightsList,
      { rightsList: [:rights, :rightsUri] },
      :xml,
      :regenerate,
      :source,
      :version,
      :metadataVersion,
      :schemaVersion,
      :state,
      :isActive,
      :reason,
      :registered,
      :updated,
      :mode,
      :event,
      :regenerate,
      :should_validate,
      :client,
      :creators,
      { creators: [:type, :id, :name, :givenName, :familyName, :affiliation] },
      :contributors,
      { contributors: [:type, :id, :name, :givenName, :familyName, :contributorType] },
      :altenateIdentifiers,
      { alternateIdentifiers: [:alternateIdentifier, :alternateIdentifierType] },
      :relatedIdentifiers,
      { relatedIdentifiers: [:relatedIdentifier, :relatedIdentifierType, :relationType, :resourceTypeGeneral, :relatedMetadataScheme, :schemeUri, :schemeType] },
      :fundingReferences,
      { fundingReferences: [:funderName, :funderIdentifier, :funderIdentifierType, :awardNumber, :awardUri, :awardTitle] },
      :geoLocations,
      { geoLocations: [{ geolocationPoint: [:pointLongitude, :pointLatitude] }, { geolocationBox: [:westBoundLongitude, :eastBoundLongitude, :southBoundLatitude, :northBoundLatitude] }, :geoLocationPlace] }
    ]
    relationships = [{ client: [data: [:type, :id]] }]

    p = params.require(:data).permit(:type, :id, attributes: attributes, relationships: relationships).reverse_merge(defaults)
    client_id = p.dig("relationships", "client", "data", "id") || current_user.try(:client_id)
    p = p.fetch("attributes").merge(client_id: client_id)

    # extract attributes from xml field and merge with attributes provided directly
    xml = p[:xml].present? ? Base64.decode64(p[:xml]).force_encoding("UTF-8") : nil
    
    meta = xml.present? ? parse_xml(xml, doi: p[:doi]) : {}

    read_attrs = [p[:creators], p[:contributors], p[:titles], p[:publisher], 
      p[:publicationYear], p[:types], p[:descriptions], p[:periodical], p[:sizes],
      p[:formats], p[:version], p[:language], p[:dates], p[:alternateIdentifiers],
      p[:relatedIdentifiers], p[:fundingReferences], p[:geoLocations], p[:rightsList],
      p[:subjects], p[:contentUrl], p[:schemaVersion]].compact

    # replace DOI, but otherwise don't touch the XML
    if meta["from"] == "datacite" && read_attrs.blank?
      xml = replace_doi(xml, doi: p[:doi] || meta["doi"])
    elsif xml.present? || read_attrs.present?
      regenerate = true
    end

    p.merge!(xml: xml) if xml.present?

    p.merge(
      creators: p[:creators] || meta["creators"],
      contributors: p[:contributors] || meta["contributors"],
      titles: p[:titles] || meta["titles"],
      publisher: p[:publisher] || meta["publisher"],
      publication_year: p[:publicationYear] || meta["publication_year"],
      types: p[:types] || meta["types"],
      descriptions: p[:descriptions] || meta["descriptions"],
      periodical: p[:periodical] || meta["periodical"],
      sizes: p[:sizes] || meta["sizes"],
      formats: p[:formats] || meta["formats"],
      version_info: p[:version] || meta["version_info"],
      language: p[:language] || meta["language"],
      dates: p[:dates] || meta["dates"],
      alternate_identifiers: p[:alternateIdentifiers] || meta["alternate_identifiers"],
      related_identifiers: p[:relatedIdentifiers] || meta["related_identifiers"],
      funding_references: p[:fundingReferences] || meta["funding_references"],
      geo_locations: p[:geoLocations] || meta["geo_locations"],
      landing_page: p[:landingPage],
      rights_list: p[:rightsList] || meta["rights_list"],
      subjects: p[:subjects] || meta["subjects"],
      content_url: p[:contentUrl] || meta["content_url"],
      schema_version: p[:schemaVersion] || meta["schema_version"],
      regenerate: p[:regenerate] || regenerate,
      last_landing_page: p[:lastLandingPage],
      last_landing_page_status: p[:lastLandingPageStatus],
      last_landing_page_status_check: p[:lastLandingPageStatusCheck],
      last_landing_page_status_result: p[:lastLandingPageStatusResult],
      last_landing_page_content_type: p[:lastLandingPageContentType]
    ).except(
      :confirmDoi, :identifier, :prefix, :suffix, :publicationYear,
      :rightsList, :alternateIdentifiers, :relatedIdentifiers, :fundingReferences, :geoLocations,
      :metadataVersion, :schemaVersion, :state, :mode, :isActive, :landingPage, 
      :created, :registered, :updated, :lastLandingPage, :version,
      :lastLandingPageStatus, :lastLandingPageStatusCheck,
      :lastLandingPageStatusResult, :lastLandingPageContentType)
  end

  def add_metadata_to_bugsnag(report)
    return nil unless params.dig(:data, :attributes, :xml).present?

    report.add_tab(:metadata, {
      metadata: Base64.decode64(params.dig(:data, :attributes, :xml))
    })
  end
end
