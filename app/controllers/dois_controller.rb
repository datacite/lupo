require 'uri'
require 'base64'

class DoisController < ApplicationController
  include ActionController::MimeResponds
  include Crosscitable

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show, :destroy, :get_url]
  before_action :set_include, only: [:index, :show, :create, :update]
  before_bugsnag_notify :add_metadata_to_bugsnag

  def index
    authorize! :read, Doi

    # if Rails.env.production? && !current_user.try(:is_admin_or_staff?)
    #   # don't use elasticsearch

    #   # support nested routes
    #   if params[:client_id].present?
    #     client = Client.where('datacentre.symbol = ?', params[:client_id]).first
    #     collection = client.present? ? client.dois : Doi.none
    #     total = client.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    #   elsif params[:provider_id].present? && params[:provider_id] != "admin"
    #     provider = Provider.where('allocator.symbol = ?', params[:provider_id]).first
    #     collection = provider.present? ? Doi.joins(:client).where("datacentre.allocator = ?", provider.id) : Doi.none
    #     total = provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i }
    #   elsif params[:id].present?
    #     collection = Doi.where(doi: params[:id])
    #     total = collection.all.size
    #   else
    #     provider = Provider.unscoped.where('allocator.symbol = ?', "ADMIN").first
    #     total = provider.present? ? provider.cached_doi_count.reduce(0) { |sum, d| sum + d[:count].to_i } : 0
    #     collection = Doi
    #   end

    #   if params[:query].present?
    #     collection = Doi.q(params[:query])
    #     total = collection.all.size
    #   end

    #   page = params[:page] || {}
    #   if page[:size].present?
    #     page[:size] = [page[:size].to_i, 1000].min
    #     max_number = page[:size] > 0 ? 10000/page[:size] : 1
    #   else
    #     page[:size] = 25
    #     max_number = 10000/page[:size]
    #   end
    #   page[:number] = page[:number].to_i > 0 ? [page[:number].to_i, max_number].min : 1
    #   total_pages = (total.to_f / page[:size]).ceil

    #   order = case params[:sort]
    #           when "name" then "dataset.doi"
    #           when "-name" then "dataset.doi DESC"
    #           when "created" then "dataset.created"
    #           else "dataset.created DESC"
    #           end

    #   @dois = collection.order(order).page(page[:number]).per(page[:size]).without_count

    #   options = {}
    #   options[:meta] = {
    #     total: total,
    #     "totalPages" => total_pages,
    #     page: page[:number].to_i
    #   }.compact

    #   options[:links] = {
    #     self: request.original_url,
    #     next: @dois.blank? ? nil : request.base_url + "/dois?" + {
    #       query: params[:query],
    #       "provider-id" => params[:provider_id],
    #       "client-id" => params[:client_id],
    #       "page[number]" => page[:number] + 1,
    #       "page[size]" => page[:size],
    #       sort: params[:sort] }.compact.to_query
    #     }.compact
    #   options[:include] = @include
    #   options[:is_collection] = true
    #   options[:params] = {
    #     :current_ability => current_ability,
    #   }

    #   render json: DoiSerializer.new(@dois, options).serialized_json, status: :ok
    # else
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

    page = page_from_params(params)

    sample_group_field = case params[:sample_group]
      when "client" then "client_id"
      when "data-center" then "client_id"
      when "provider" then "provider_id"
      when "resource-type" then "types.resourceTypeGeneral"
      else nil
    end

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
                          schema_version: params[:schema_version],
                          subject: params[:subject],
                          link_check_status: params[:link_check_status],
                          link_check_has_schema_org: params[:link_check_has_schema_org],
                          link_check_body_has_pid: params[:link_check_body_has_pid],
                          link_check_found_schema_org_id: params[:link_check_found_schema_org_id],
                          link_check_found_dc_identifier: params[:link_check_found_dc_identifier],
                          link_check_found_citation_doi: params[:link_check_found_citation_doi],
                          link_check_redirect_count_gte: params[:link_check_redirect_count_gte],
                          sample_group: sample_group_field,
                          sample_size: params[:sample],
                          source: params[:source],
                          page: page,
                          sort: sort,
                          random: params[:random])
    end

    begin
      # If we're using sample groups we need to unpack the results from the aggregation bucket hits.
      if sample_group_field.present?
        sample_dois = []
        response.response.aggregations.samples.buckets.each do |bucket|
          bucket.samples_hits.hits.hits.each do |hit|
            sample_dois << hit._source
          end
        end
      end

      # Results to return are either our sample group dois or the regular hit results
      if sample_dois
        results = sample_dois
        # The total is just the length because for sample grouping we get everything back in one shot no pagination.
        total = sample_dois.length
        total_pages = 1
      else
        results = response.results.results
        total = response.results.total
        total_pages = page[:size] > 0 ? ([total.to_f, 10000].min / page[:size]).ceil : 0
      end

      states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
      resource_types = total > 0 ? facet_by_resource_type(response.response.aggregations.resource_types.buckets) : nil
      created = total > 0 ? facet_by_year(response.response.aggregations.created.buckets) : nil
      registered = total > 0 ? facet_by_year(response.response.aggregations.registered.buckets) : nil
      providers = total > 0 ? facet_by_provider(response.response.aggregations.providers.buckets) : nil
      clients = total > 0 ? facet_by_client(response.response.aggregations.clients.buckets) : nil
      prefixes = total > 0 ? facet_by_key(response.response.aggregations.prefixes.buckets) : nil
      schema_versions = total > 0 ? facet_by_schema(response.response.aggregations.schema_versions.buckets) : nil
      sources = total > 0 ? facet_by_key(response.response.aggregations.sources.buckets) : nil
      link_checks_status = total > 0 ? facet_by_cumulative_year(response.response.aggregations.link_checks_status.buckets) : nil
      links_with_schema_org = total > 0 ? facet_by_cumulative_year(response.response.aggregations.link_checks_has_schema_org.buckets) : nil
      link_checks_schema_org_id = total > 0 ? response.response.aggregations.link_checks_schema_org_id.value : nil
      link_checks_dc_identifier = total > 0 ? response.response.aggregations.link_checks_dc_identifier.value : nil
      link_checks_citation_doi = total > 0 ? response.response.aggregations.link_checks_citation_doi.value : nil
      links_checked = total > 0 ? response.response.aggregations.links_checked.value : nil
      subjects = total > 0 ? facet_by_key(response.response.aggregations.subjects.buckets) : nil


      respond_to do |format|
        format.json do
          @dois = results
          options = {}
          options[:meta] = {
            total: total,
            "totalPages" => total_pages,
            page: page[:number],
            states: states,
            "resourceTypes" => resource_types,
            created: created,
            registered: registered,
            providers: providers,
            clients: clients,
            prefixes: prefixes,
            "schemaVersions" => schema_versions,
            sources: sources,
            "linkChecksStatus" => link_checks_status,
            "linksChecked" => links_checked,
            "linksWithSchemaOrg" => links_with_schema_org,
            "linkChecksSchemaOrgId" => link_checks_schema_org_id,
            "linkChecksDcIdentifier" => link_checks_dc_identifier,
            "linkChecksCitationDoi" => link_checks_citation_doi,
            subjects: subjects
          }.compact

          options[:links] = {
            self: request.original_url,
            next: @dois.blank? ? nil : request.base_url + "/dois?" + {
              query: params[:query],
              "provider-id" => params[:provider_id],
              "client-id" => params[:client_id],
              fields: params[:fields],
              "page[cursor]" => Array.wrap(@dois.last[:sort]).first,
              "page[size]" => page[:size] }.compact.to_query
            }.compact
          options[:include] = @include
          options[:is_collection] = true
          options[:params] = {
            :current_ability => current_ability,
          }

          render json: DoiSerializer.new(@dois, options).serialized_json, status: :ok
        end
        format.citation do
          # fetch formatted citations
          render citation: response.records.to_a, style: params[:style] || "apa", locale: params[:locale] || "en-US"
        end
        format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :csv, :schema_org) { render request.format.to_sym => response.records.to_a }
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      Bugsnag.notify(exception)

      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    authorize! :read, @doi

    respond_to do |format|
      format.json do
        options = {}
        options[:include] = @include
        options[:is_collection] = false
        options[:params] = {
          current_ability: current_ability,
          detail: true
        }

        render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
      end
      format.citation do
        # fetch formatted citation
        render citation: @doi, style: params[:style] || "apa", locale: params[:locale] || "en-US"
      end
      format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :csv, :schema_org) { render request.format.to_sym => @doi }
    end
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
        # only update client_id

        authorize! :transfer, @doi
        @doi.assign_attributes(safe_params.slice(:client_id))
      else
        authorize! :update, @doi
        @doi.assign_attributes(safe_params.except(:doi, :client_id))
      end
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

  def random
    prefix = params[:prefix].presence || "10.5072"
    doi = generate_random_doi(prefix, number: params[:number])

    render json: { doi: doi }.to_json
  end

  def get_url
    authorize! :get_url, @doi

    if !@doi.is_registered_or_findable? || %w(europ ethz).include?(@doi.provider_id) || %w(Crossref).include?(@doi.agency)
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

  # legacy method
  def status
    render json: { message: "Not Implemented." }.to_json, status: :not_implemented
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
      @include = @include & [:client, :media]
    else
      @include = [:client, :media]
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
          { schemaOrgId: [] },
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
      { creators: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme] }, :name, :givenName, :familyName, :affiliation] },
      :contributors,
      { contributors: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme] }, :name, :givenName, :familyName, :affiliation, :contributorType] },
      :identifiers,
      { identifiers: [:identifier, :identifierType] },
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

    if xml.present?
      # remove optional utf-8 bom
      xml.gsub!("\xEF\xBB\xBF", '')

      # remove leading and trailing whitespace
      xml = xml.strip
    end

    meta = xml.present? ? parse_xml(xml, doi: p[:doi]) : {}
    xml = meta["string"]

    read_attrs = [p[:creators], p[:contributors], p[:titles], p[:publisher],
      p[:publicationYear], p[:types], p[:descriptions], p[:container], p[:sizes],
      p[:formats], p[:version], p[:language], p[:dates], p[:identifiers],
      p[:relatedIdentifiers], p[:fundingReferences], p[:geoLocations], p[:rightsList],
      p[:subjects], p[:contentUrl], p[:schemaVersion]].compact

    # replace DOI, but otherwise don't touch the XML
    # use Array.wrap(read_attrs.first) as read_attrs may also be [[]]
    if meta["from"] == "datacite" && Array.wrap(read_attrs.first).blank?
      xml = replace_doi(xml, doi: p[:doi] || meta["doi"])
    elsif xml.present? || Array.wrap(read_attrs.first).present?
      regenerate = true
    end

    p.merge!(xml: xml) if xml.present?

    read_attrs_keys = [:creators, :contributors, :titles, :publisher,
      :publicationYear, :types, :descriptions, :container, :sizes,
      :formats, :language, :dates, :identifiers,
      :relatedIdentifiers, :fundingReferences, :geoLocations, :rightsList,
      :subjects, :contentUrl, :schemaVersion]

    # merge attributes from xml into regular attributes
    # make sure we don't accidentally set any attributes to nil
    read_attrs_keys.each do |attr|
      p.merge!(attr.to_s.underscore => p[attr].presence || meta[attr.to_s.underscore]) if p.has_key?(attr) || meta[attr.to_s.underscore].present?
    end
    p.merge!(version_info: p[:version] || meta["version_info"]) if p.has_key?(:version_info) || meta["version_info"].present?

    # only update landing_page info if something is received via API to not overwrite existing data
    p.merge!(landing_page: p[:landingPage]) if p[:landingPage].present?

    p.merge(
      regenerate: p[:regenerate] || regenerate
    ).except(
      :confirmDoi, :prefix, :suffix, :publicationYear,
      :rightsList, :relatedIdentifiers, :fundingReferences, :geoLocations,
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
