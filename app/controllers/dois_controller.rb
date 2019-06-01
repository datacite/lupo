require 'uri'
require 'base64'
require 'benchmark'

class DoisController < ApplicationController
  include ActionController::MimeResponds
  include Crosscitable

  prepend_before_action :authenticate_user!
  before_action :set_doi, only: [:show, :destroy, :get_url]
  before_action :set_include, only: [:index, :show, :create, :update]
  before_action :set_raven_context, only: [:create, :update, :validate]

  def index
    authorize! :read, Doi

    logger = Logger.new(STDOUT)

    sort = case params[:sort]
          when "name" then { "doi" => { order: 'asc' }}
          when "-name" then { "doi" => { order: 'desc' }}
          when "created" then { created: { order: 'asc' }}
          when "-created" then { created: { order: 'desc' }}
          when "updated" then { updated: { order: 'asc' }}
          when "-updated" then { updated: { order: 'desc' }}
          when "published" then { published: { order: 'asc' }}
          when "-published" then { published: { order: 'desc' }}
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

    response = nil

    if params[:id].present?
      logger.info "[Benchmark] find_by_id " + Benchmark.ms {
        response = Doi.find_by_id(params[:id])
      }.to_s + " ms"
    elsif params[:ids].present?
      response = Doi.find_by_id(params[:ids], page: page, sort: sort)
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
                          random: params[:random],
                          current_user: current_user)
    end

    begin
      if response.took > 1000
        logger.warn "[Benchmark Warning] Elasticsearch request " + response.took.to_s + " ms"
      else
        logger.info "[Benchmark] Elasticsearch request " + response.took.to_s + " ms"
      end

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
        results = response.results
        total = response.results.total
        total_for_pages = page[:cursor].present? ? total.to_f : [total.to_f, 10000].min
        total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0
      end

      # we need to define those variables before the block
      states = nil
      resource_types = nil
      created = nil
      registered = nil
      providers = nil
      clients = nil
      prefixes = nil
      schema_versions = nil
      sources = nil
      link_checks_status = nil
      links_with_schema_org = nil
      link_checks_schema_org_id = nil
      link_checks_dc_identifier = nil
      link_checks_citation_doi = nil
      links_checked = nil
      subjects = nil
      bma = Benchmark.ms {
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
      }
      if bma > 1000
        logger.warn "[Benchmark Warning] aggregations " + bma.to_s + " ms"
      else
        logger.info "[Benchmark] aggregations " + bma.to_s + " ms"
      end

      respond_to do |format|
        format.json do
          options = {}
          options[:meta] = {
            total: total,
            "totalPages" => total_pages,
            page: page[:cursor].blank? && page[:number].present? ? page[:number] : nil,
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
            next: results.size < page[:size] || page[:size] == 0 ? nil : request.base_url + "/dois?" + {
              query: params[:query],
              "provider-id" => params[:provider_id],
              "client-id" => params[:client_id],
              "page[cursor]" => page[:cursor].present? ? Array.wrap(results.to_a.last[:sort]).first : nil,
              "page[number]" => page[:cursor].blank? && page[:number].present? ? page[:number] + 1 : nil,
              "page[size]" => page[:size] }.compact.to_query
            }.compact
          options[:include] = @include
          options[:is_collection] = true
          options[:params] = {
            :current_ability => current_ability,
          }

          bmr = Benchmark.ms {
            render json: DoiSerializer.new(results, options).serialized_json, status: :ok
          }
          
          if bmr > 3000
            logger.warn "[Benchmark Warning] render " + bmr.to_s + " ms"
          else
            logger.info "[Benchmark] render " + bmr.to_s + " ms"
          end
        end

        format.citation do
          # fetch formatted citations
          render citation: response.records.to_a, style: params[:style] || "apa", locale: params[:locale] || "en-US"
        end
        header = %w(doi url registered state resourceTypeGeneral resourceType title author publisher publicationYear)
        format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :schema_org) { render request.format.to_sym => response.records.to_a }
        format.csv { render request.format.to_sym => response.records.to_a, header: header }
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
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
      header = %w(doi url registered state resourceTypeGeneral resourceType title author publisher publicationYear)
      format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :schema_org) { render request.format.to_sym => @doi }
      format.csv { render request.format.to_sym =>  @doi, header: header }
    end
  end

  def validate
    logger = Logger.new(STDOUT)
    # logger.info safe_params.inspect

    doi = Doi.where(doi: params.dig(:data,:attributes,:doi)).first
    exists = doi.present?

    @doi = Doi.new(safe_params.merge(only_validate: true, exists: exists))

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
      render json: serialize_errors(@doi.errors.messages), status: :ok
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
      render json: serialize_errors(@doi.errors), include: @include, status: :unprocessable_entity
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
        @doi.assign_attributes(safe_params.except(:doi, :client_id).merge(exists: exists))
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
      render json: serialize_errors(@doi.errors.messages), include: @include, status: :unprocessable_entity
    end
  end

  def undo
    logger = Logger.new(STDOUT)

    @doi = Doi.where(doi: safe_params[:doi]).first
    fail ActiveRecord::RecordNotFound unless @doi.present?

    authorize! :undo, @doi

    if @doi.audits.last.undo
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        detail: true
      }

      render json: DoiSerializer.new(@doi, options).serialized_json, status: :ok
    else
      logger.warn @doi.errors.messages
      render json: serialize_errors(@doi.errors.messages), include: @include, status: :unprocessable_entity
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
        render json: serialize_errors(@doi.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  def random
    if params[:prefix].present?
      doi = generate_random_doi(params[:prefix], number: params[:number])
      render json: { doi: doi }.to_json
    else
      render json: { errors: [{ status: "422", title: "Parameter prefix is required" }] }.to_json, status: :unprocessable_entity
    end
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

    dois = Doi.get_dois(prefix: client_prefix.prefix, username: current_user.uid.upcase, password: current_user.password)
    if dois.length > 0
      render json: { dois: dois }.to_json, status: :ok
    else
      head :no_content
    end
  end

  def set_url
    authorize! :set_url, Doi
    Doi.set_url

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
      :subjects,
      { subjects: [:subject, :subjectScheme, :schemeUri, :valueUri, :lang] },
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
      { contentUrl: [] },
      :sizes,
      { sizes: [] },
      :formats,
      { formats: [] },
      :language,
      :descriptions,
      { descriptions: [:description, :descriptionType, :lang] },
      :rightsList,
      { rightsList: [:rights, :rightsUri, :lang] },
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
      { creators: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme, :schemeUri] }, :name, :givenName, :familyName, :affiliation, { affiliation: [] }, :lang] },
      :contributors,
      { contributors: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme, :schemeUri] }, :name, :givenName, :familyName, :affiliation, { affiliation: [] }, :contributorType, :lang] },
      :identifiers,
      { identifiers: [:identifier, :identifierType] },
      :relatedIdentifiers,
      { relatedIdentifiers: [:relatedIdentifier, :relatedIdentifierType, :relationType, :relatedMetadataScheme, :schemeUri, :schemeType, :resourceTypeGeneral, :relatedMetadataScheme, :schemeUri, :schemeType] },
      :fundingReferences,
      { fundingReferences: [:funderName, :funderIdentifier, :funderIdentifierType, :awardNumber, :awardUri, :awardTitle] },
      :geoLocations,
      { geoLocations: [{ geoLocationPoint: [:pointLongitude, :pointLatitude] }, { geoLocationBox: [:westBoundLongitude, :eastBoundLongitude, :southBoundLatitude, :northBoundLatitude] }, :geoLocationPlace] }
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
    p[:schemaVersion] =  METADATA_FORMATS.include?(meta["from"]) ? LAST_SCHEMA_VERSION : p[:schemaVersion]
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
      p.merge!(attr.to_s.underscore => p[attr].presence || meta[attr.to_s.underscore].presence || p[attr]) if p.has_key?(attr) || meta.has_key?(attr.to_s.underscore)
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
      :lastLandingPageStatusResult, :lastLandingPageContentType, :contentUrl)
  end

  def set_raven_context
    return nil unless params.dig(:data, :attributes, :xml).present?

    Raven.extra_context metadata: Base64.decode64(params.dig(:data, :attributes, :xml))
  end
end
