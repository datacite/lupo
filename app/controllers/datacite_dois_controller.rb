require 'uri'
require 'base64'
require 'pp'

class DataciteDoisController < ApplicationController
  include ActionController::MimeResponds
  include Crosscitable

  prepend_before_action :authenticate_user!
  before_action :set_include, only: [:index, :show, :create, :update]
  before_action :set_raven_context, only: [:create, :update, :validate]

  def index
    sort = case params[:sort]
           when "name" then { "doi" => { order: 'asc' }}
           when "-name" then { "doi" => { order: 'desc' }}
           when "created" then { created: { order: 'asc' }}
           when "-created" then { created: { order: 'desc' }}
           when "updated" then { updated: { order: 'asc' }}
           when "-updated" then { updated: { order: 'desc' }}
           when "published" then { published: { order: 'asc' }}
           when "-published" then { published: { order: 'desc' }}
           when "view-count" then { view_count: { order: 'asc' }}
           when "-view-count" then { view_count: { order: 'desc' }}
           when "download-count" then { download_count: { order: 'asc' }}
           when "-download-count" then { download_count: { order: 'desc' }}
           when "citation-count" then { citation_count: { order: 'asc' }}
           when "-citation-count" then { citation_count: { order: 'desc' }}
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

    # only show findable DOIs to anonymous users and role user
    params[:state] = "findable" if current_user.nil? || current_user.role_id == "user"

    if params[:id].present?
      response = DataciteDoi.find_by_id(params[:id])
    elsif params[:ids].present?
      response = DataciteDoi.find_by_ids(params[:ids], page: page, sort: sort)
    else
      response = DataciteDoi.query(params[:query],
                          state: params[:state],
                          published: params[:published],
                          created: params[:created],
                          registered: params[:registered],
                          provider_id: params[:provider_id],
                          consortium_id: params[:consortium_id],
                          client_id: params[:client_id],
                          affiliation_id: params[:affiliation_id],
                          funder_id: params[:funder_id],
                          re3data_id: params[:re3data_id],
                          opendoar_id: params[:opendoar_id],
                          license: params[:license],
                          certificate: params[:certificate],
                          prefix: params[:prefix],
                          user_id: params[:user_id],
                          resource_type_id: params[:resource_type_id],
                          resource_type: params[:resource_type],
                          schema_version: params[:schema_version],
                          subject: params[:subject],
                          field_of_science: params[:field_of_science],
                          has_citations: params[:has_citations],
                          has_references: params[:has_references],
                          has_parts: params[:has_parts],
                          has_part_of: params[:has_part_of],
                          has_versions: params[:has_versions],
                          has_version_of: params[:has_version_of],
                          has_views: params[:has_views],
                          has_downloads: params[:has_downloads],
                          has_person: params[:has_person],
                          has_affiliation: params[:has_affiliation],
                          has_funder: params[:has_funder],
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
                          scroll_id: params[:scroll_id],
                          page: page,
                          sort: sort,
                          random: params[:random])
    end

    begin
      # If we're using sample groups we need to unpack the results from the aggregation bucket hits.
      if sample_group_field.present?
        sample_dois = []
        response.aggregations.samples.buckets.each do |bucket|
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
      elsif page[:scroll].present?
        # if scroll_id has expired
        fail ActiveRecord::RecordNotFound unless response.scroll_id.present?

        results = response.results
        total = response.total
      else
        results = response.results
        total = response.results.total
        total_for_pages = page[:cursor].nil? ? [total.to_f, 10000].min : total.to_f
        total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0
      end

      if page[:scroll].present?
        options = {}
        options[:meta] = {
          total: total,
          "scroll-id" => response.scroll_id,
        }.compact
        options[:links] = {
          self: request.original_url,
          next: results.size < page[:size] || page[:size] == 0 ? nil : request.base_url + "/dois?" + {
            "scroll-id" => response.scroll_id,
            "page[scroll]" => page[:scroll],
            "page[size]" => page[:size] }.compact.to_query
          }.compact
        options[:is_collection] = true
        options[:params] = {
          current_ability: current_ability,
          detail: params[:detail],
          affiliation: params[:affiliation],
          is_collection: options[:is_collection]
        }

        # sparse fieldsets
        fields = fields_from_params(params)
        if fields
          render json: DataciteDoiSerializer.new(results, options.merge(fields: fields)).serialized_json, status: :ok
        else
          render json: DataciteDoiSerializer.new(results, options).serialized_json, status: :ok
        end
      else
        states = total.positive? ? facet_by_key(response.aggregations.states.buckets) : nil
        resource_types = total.positive? ? facet_by_combined_key(response.aggregations.resource_types.buckets) : nil
        published = total.positive? ? facet_by_range(response.aggregations.published.buckets) : nil
        created = total.positive? ? facet_by_key_as_string(response.aggregations.created.buckets) : nil
        registered = total.positive? ? facet_by_key_as_string(response.aggregations.registered.buckets) : nil
        providers = total.positive? ? facet_by_combined_key(response.aggregations.providers.buckets) : nil
        clients = total.positive? ? facet_by_combined_key(response.aggregations.clients.buckets) : nil
        prefixes = total.positive? ? facet_by_key(response.aggregations.prefixes.buckets) : nil
        schema_versions = total.positive? ? facet_by_schema(response.aggregations.schema_versions.buckets) : nil

        affiliations = total.positive? ? facet_by_combined_key(response.aggregations.affiliations.buckets) : nil
        # sources = total.positive? ? facet_by_key(response.aggregations.sources.buckets) : nil
        subjects = total.positive? ? facet_by_key(response.aggregations.subjects.buckets) : nil
        fields_of_science = total.positive? ? facet_by_fos(response.aggregations.fields_of_science.subject.buckets) : nil
        certificates = total.positive? ? facet_by_key(response.aggregations.certificates.buckets) : nil
        licenses = total.positive? ? facet_by_license(response.aggregations.licenses.buckets) : nil
        
        link_checks_status = total.positive? ? facet_by_cumulative_year(response.aggregations.link_checks_status.buckets) : nil
        # links_with_schema_org = total.positive? ? facet_by_cumulative_year(response.aggregations.link_checks_has_schema_org.buckets) : nil
        # link_checks_schema_org_id = total.positive? ? response.aggregations.link_checks_schema_org_id.value : nil
        # link_checks_dc_identifier = total.positive? ? response.aggregations.link_checks_dc_identifier.value : nil
        # link_checks_citation_doi = total.positive? ? response.aggregations.link_checks_citation_doi.value : nil
        # links_checked = total.positive? ? response.aggregations.links_checked.value : nil

        citations = total.positive? ? metric_facet_by_year(response.aggregations.citations.buckets) : nil
        views = total.positive? ? metric_facet_by_year(response.aggregations.views.buckets) : nil
        downloads = total.positive? ? metric_facet_by_year(response.aggregations.downloads.buckets) : nil

        respond_to do |format|
          format.json do
            options = {}
            options[:meta] = {
              total: total,
              "totalPages" => total_pages,
              page: page[:cursor].nil? && page[:number].present? ? page[:number] : nil,
              states: states,
              "resourceTypes" => resource_types,
              created: created,
              published: published,
              registered: registered,
              providers: providers,
              clients: clients,
              affiliations: affiliations,
              prefixes: prefixes,
              certificates: certificates,
              licenses: licenses,
              "schemaVersions" => schema_versions,
              # sources: sources,
              "linkChecksStatus" => link_checks_status,
              # "linksChecked" => links_checked,
              # "linksWithSchemaOrg" => links_with_schema_org,
              # "linkChecksSchemaOrgId" => link_checks_schema_org_id,
              # "linkChecksDcIdentifier" => link_checks_dc_identifier,
              # "linkChecksCitationDoi" => link_checks_citation_doi,
              subjects: subjects,
              "fieldsOfScience" => fields_of_science,
              citations: citations,
              views: views,
              downloads: downloads,
            }.compact

            options[:links] = {
              self: request.original_url,
              next: results.size < page[:size] || page[:size] == 0 ? nil : request.base_url + "/dois?" + {
                query: params[:query],
                "provider-id" => params[:provider_id],
                "consortium-id" => params[:consortium_id],
                "client-id" => params[:client_id],
                "funder-id" => params[:funder_id],
                "affiliation-id" => params[:affiliation_id],
                "resource-type-id" => params[:resource_type_id],
                prefix: params[:prefix],
                certificate: params[:certificate],
                published: params[:published],
                created: params[:created],
                registered: params[:registered],
                "has-citations" => params[:has_citations],
                "has-references" => params[:has_references],
                "has-parts" => params[:has_parts],
                "has-part-of" => params[:has_part_of],
                "has-versions" => params[:has_versions],
                "has-version-of" => params[:has_version_of],
                "has-views" => params[:has_views],
                "has-downloads" => params[:has_downloads],
                "has-person" => params[:has_person],
                "has-affiliation" => params[:has_affiliation],
                "has-funder" => params[:has_funder],
                detail: params[:detail],
                composite: params[:composite],
                affiliation: params[:affiliation],
                # The cursor link should be an array of values, but we want to encode it into a single string for the URL
                "page[cursor]" => page[:cursor] ? make_cursor(results) : nil,
                "page[number]" => page[:cursor].nil? && page[:number].present? ? page[:number] + 1 : nil,
                "page[size]" => page[:size] }.compact.to_query
              }.compact
            options[:include] = @include
            options[:is_collection] = true
            options[:params] = {
              current_ability: current_ability,
              detail: params[:detail],
              composite: params[:composite],
              affiliation: params[:affiliation],
              is_collection: options[:is_collection],
            }

            # sparse fieldsets
            fields = fields_from_params(params)
            if fields
              render json: DataciteDoiSerializer.new(results, options.merge(fields: fields)).serialized_json, status: :ok
            else
              render json: DataciteDoiSerializer.new(results, options).serialized_json, status: :ok
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
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exception
      message = JSON.parse(exception.message[6..-1]).to_h.dig("error", "root_cause", 0, "reason")

      render json: { "errors" => { "title" => message }}.to_json, status: :bad_request
    end
  end

  def show
    # only show findable DataCite DOIs to anonymous users and role user
    # use current_user role to determine permissions to access draft and registered dois
    # instead of using ability
    # response = DataciteDoi.find_by_id(params[:id])
    doi = DataciteDoi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound if not_allowed_by_doi_and_user(doi: doi, user: current_user)

    respond_to do |format|
      format.json do
        # doi = response.results.first
        fail ActiveRecord::RecordNotFound if not_allowed_by_doi_and_user(doi: doi, user: current_user)

        options = {}
        options[:include] = @include
        options[:is_collection] = false
        options[:params] = {
          current_ability: current_ability,
          detail: true,
          composite: nil,
          affiliation: params[:affiliation],
        }

        render json: DataciteDoiSerializer.new(doi, options).serialized_json, status: :ok
      end

      # doi = response.records.first
      fail ActiveRecord::RecordNotFound if not_allowed_by_doi_and_user(doi: doi, user: current_user)

      format.citation do
        # fetch formatted citation
        render citation: doi, style: params[:style] || "apa", locale: params[:locale] || "en-US"
      end
      header = %w(doi url registered state resourceTypeGeneral resourceType title author publisher publicationYear)
      format.any(:bibtex, :citeproc, :codemeta, :crosscite, :datacite, :datacite_json, :jats, :ris, :schema_org) { render request.format.to_sym => doi }
      format.csv { render request.format.to_sym => doi, header: header }
    end
  end

  def validate
    @doi = DataciteDoi.new(safe_params.merge(only_validate: true))

    authorize! :validate, @doi

    if @doi.valid?
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        :current_ability => current_ability,
      }

      render json: DataciteDoiSerializer.new(@doi, options).serialized_json, status: :ok
    else
      logger.info @doi.errors.messages
      render json: serialize_errors(@doi.errors.messages), status: :ok
    end
  end

  def create
    fail CanCan::AuthorizationNotPerformed if current_user.blank?
    @doi = DataciteDoi.new(safe_params)

    # capture username and password for reuse in the handle system
    @doi.current_user = current_user

    authorize! :new, @doi

    if @doi.save
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        detail: true,
        affiliation: params[:affiliation]
      }

      render json: DataciteDoiSerializer.new(@doi, options).serialized_json, status: :created, location: @doi
    else
      logger.error @doi.errors.inspect
      render json: serialize_errors(@doi.errors), include: @include, status: :unprocessable_entity
    end
  end

  def update
    @doi = DataciteDoi.where(doi: params[:id]).first
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
        if safe_params[:schema_version].blank?
          @doi.assign_attributes(safe_params.except(:doi, :client_id).merge(schema_version: @doi[:schema_version] || LAST_SCHEMA_VERSION))
        else
          @doi.assign_attributes(safe_params.except(:doi, :client_id))
        end
      end
    else
      doi_id = validate_doi(params[:id])
      fail ActiveRecord::RecordNotFound unless doi_id.present?

      @doi = DataciteDoi.new(safe_params.merge(doi: doi_id))
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
        detail: true,
        affiliation: params[:affiliation],
      }

      render json: DataciteDoiSerializer.new(@doi, options).serialized_json, status: exists ? :ok : :created
    else
      logger.error @doi.errors.messages
      render json: serialize_errors(@doi.errors.messages), include: @include, status: :unprocessable_entity
    end
  end

  def undo
    @doi = DataciteDoi.where(doi: safe_params[:doi]).first
    fail ActiveRecord::RecordNotFound if @doi.blank?

    authorize! :undo, @doi

    if @doi.audits.last.undo
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        detail: true,

      }

      render json: DataciteDoiSerializer.new(@doi, options).serialized_json, status: :ok
    else
      logger.error @doi.errors.messages
      render json: serialize_errors(@doi.errors.messages), include: @include, status: :unprocessable_entity
    end
  end

  def destroy
    @doi = DataciteDoi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound if @doi.blank?

    authorize! :destroy, @doi

    if @doi.draft?
      if @doi.destroy
        head :no_content
      else
        logger.error @doi.errors.inspect
        render json: serialize_errors(@doi.errors), status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: { errors: [{ status: "405", title: "Method not allowed" }] }.to_json, status: :method_not_allowed
    end
  end

  def random
    if params[:prefix].present?
      dois = generate_random_dois(params[:prefix], number: params[:number], size: params[:size])
      render json: { dois: dois }.to_json
    else
      render json: { errors: [{ status: "422", title: "Parameter prefix is required" }] }.to_json, status: :unprocessable_entity
    end
  end

  def get_url
    @doi = DataciteDoi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound if @doi.blank?

    authorize! :get_url, @doi

    if !@doi.is_registered_or_findable? || %w(europ).include?(@doi.provider_id) || @doi.type == "OtherDoi"
      url = @doi.url
      head :no_content && return if url.blank?
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

    client = Client.where("datacentre.symbol = ?", current_user.uid.upcase).first
    client_prefix = client.prefixes.first
    head :no_content && return if client_prefix.blank?

    dois = DataciteDoi.get_dois(prefix: client_prefix.uid, username: current_user.uid.upcase, password: current_user.password)
    if dois.length.positive?
      render json: { dois: dois }.to_json, status: :ok
    else
      head :no_content
    end
  end

  def set_url
    authorize! :set_url, Doi
    DataciteDoi.set_url

    render json: { message: "Adding missing URLs queued." }.to_json, status: :ok
  end

  # legacy method
  def status
    render json: { message: "Not Implemented." }.to_json, status: :not_implemented
  end

  protected

  def set_include
    if params[:include].present?
      @include = params[:include].split(",").map { |i| i.downcase.underscore.to_sym }

      @include = @include & [:client, :media]
    else
      @include = []
    end
  end

  private

  def safe_params
    fail JSON::ParserError, "You need to provide a payload following the JSONAPI spec" unless params[:data].present?

    # alternateIdentifiers as alias for identifiers
    # easier before strong_parameters are checked
    params[:data][:attributes][:identifiers] = Array.wrap(params.dig(:data, :attributes, :alternateIdentifiers)).map do |a|
      { identifier: a[:alternateIdentifier],
        identifierType: a[:alternateIdentifierType] }
    end if params.dig(:data, :attributes).present? && params.dig(:data, :attributes, :identifiers).blank?

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
      { landingPage: [
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
      { rightsList: [:rights, :rightsUri, :rightsIdentifier, :rightsIdentifierScheme, :schemeUri, :lang] },
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
      { creators: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme, :schemeUri] }, :name, :givenName, :familyName, { affiliation: [:name, :affiliationIdentifier, :affiliationIdentifierScheme, :schemeUri] }, :lang] },
      :contributors,
      { contributors: [:nameType, { nameIdentifiers: [:nameIdentifier, :nameIdentifierScheme, :schemeUri] }, :name, :givenName, :familyName, { affiliation: [:name, :affiliationIdentifier, :affiliationIdentifierScheme, :schemeUri] }, :contributorType, :lang] },
      :identifiers,
      { identifiers: [:identifier, :identifierType] },
      :alternateIdentifiers,
      { alternateIdentifiers: [:alternateIdentifier, :alternateIdentifierType] },
      :relatedIdentifiers,
      { relatedIdentifiers: [:relatedIdentifier, :relatedIdentifierType, :relationType, :relatedMetadataScheme, :schemeUri, :schemeType, :resourceTypeGeneral, :relatedMetadataScheme, :schemeUri, :schemeType] },
      :fundingReferences,
      { fundingReferences: [:funderName, :funderIdentifier, :funderIdentifierType, :awardNumber, :awardUri, :awardTitle] },
      :geoLocations,
      { geoLocations: [{ geoLocationPoint: [:pointLongitude, :pointLatitude] }, { geoLocationBox: [:westBoundLongitude, :eastBoundLongitude, :southBoundLatitude, :northBoundLatitude] }, :geoLocationPlace] },
      :container,
      { container: [:type, :identifier, :identifierType, :title, :volume, :issue, :firstPage, :lastPage] },
      :published,
      :downloadsOverTime,
      { downloadsOverTime: [:yearMonth, :total] },
      :viewsOverTime,
      { viewsOverTime: [:yearMonth, :total] },
      :citationsOverTime,
      { citationsOverTime: [:year, :total] },
      :citationCount,
      :downloadCount,
      :partCount,
      :partOfCount,
      :referenceCount,
      :versionCount,
      :versionOfCount,
      :viewCount,
    ]
    relationships = [{ client: [data: [:type, :id]] }]

    # default values for attributes stored as JSON
    defaults = { data: { titles: [], descriptions: [], types: {}, container: {}, dates: [], subjects: [], rightsList: [], creators: [], contributors: [], sizes: [], formats: [], contentUrl: [], identifiers: [], relatedIdentifiers: [], fundingReferences: [], geoLocations: [] }}

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

    p[:creators]&.each do |c|
      fail(ActionController::UnpermittedParameters, ["nameIdentifiers must be an Array"]) if c[:nameIdentifiers]&.respond_to?(:keys)
    end

    p[:contributors]&.each do |c|
      fail(ActionController::UnpermittedParameters, ["nameIdentifiers must be an Array"]) if c[:nameIdentifiers]&.respond_to?(:keys)
    end

    meta = xml.present? ? parse_xml(xml, doi: p[:doi]) : {}
    p[:schemaVersion] = METADATA_FORMATS.include?(meta["from"]) ? LAST_SCHEMA_VERSION : p[:schemaVersion]
    xml = meta["string"]
  
    # if metadata for DOIs from other registration agencies are not found
    fail ActiveRecord::RecordNotFound if meta["state"] == "not_found"

    read_attrs = [p[:creators], p[:contributors], p[:titles], p[:publisher],
      p[:publicationYear], p[:types], p[:descriptions], p[:container], p[:sizes],
      p[:formats], p[:version], p[:language], p[:dates], p[:identifiers],
      p[:relatedIdentifiers], p[:fundingReferences], p[:geoLocations], p[:rightsList],
      p[:subjects], p[:contentUrl], p[:schemaVersion]].compact

    # generate random DOI if no DOI is provided
    if p[:doi].blank? && p[:prefix].present?
      p[:doi] = generate_random_dois(p[:prefix]).first
    end

    # replace DOI, but otherwise don't touch the XML
    # use Array.wrap(read_attrs.first) as read_attrs may also be [[]]
    if meta["from"] == "datacite" && Array.wrap(read_attrs.first).blank?
      xml = replace_doi(xml, doi: p[:doi] || meta["doi"])
    elsif xml.present? || Array.wrap(read_attrs.first).present?
      regenerate = true
    end

    p.merge!(xml: xml) if xml.present?

    read_attrs_keys = [:url, :creators, :contributors, :titles, :publisher,
      :publicationYear, :types, :descriptions, :container, :sizes,
      :formats, :language, :dates, :identifiers, :relatedIdentifiers,
      :fundingReferences, :geoLocations, :rightsList, :agency,
      :subjects, :contentUrl, :schemaVersion]

    # merge attributes from xml into regular attributes
    # make sure we don't accidentally set any attributes to nil
    read_attrs_keys.each do |attr|
      p.merge!(attr.to_s.underscore => p[attr] || meta[attr.to_s.underscore] || p[attr]) if p.has_key?(attr) || meta.has_key?(attr.to_s.underscore)
    end

    # handle version metadata
    p[:version_info] = p[:version] || meta["version_info"] if p.has_key?(:version) || meta["version_info"].present?
    
    # only update landing_page info if something is received via API to not overwrite existing data
    p.merge!(landing_page: p[:landingPage]) if p[:landingPage].present?
    
    p.merge(
      regenerate: p[:regenerate] || regenerate
    ).except(
      # ignore camelCase keys, and read-only keys
      :confirmDoi, :prefix, :suffix, :publicationYear, :alternateIdentifiers,
      :rightsList, :relatedIdentifiers, :fundingReferences, :geoLocations,
      :metadataVersion, :schemaVersion, :state, :mode, :isActive, :landingPage,
      :created, :registered, :updated, :published, :lastLandingPage, :version,
      :lastLandingPageStatus, :lastLandingPageStatusCheck,
      :lastLandingPageStatusResult, :lastLandingPageContentType, :contentUrl,
      :viewsOverTime, :downloadsOverTime, :citationsOverTime, :citationCount, :downloadCount,
      :partCount, :partOfCount, :referenceCount, :versionCount, :versionOfCount, :viewCount)
  end

  def set_raven_context
    return nil if params.dig(:data, :attributes, :xml).blank?

    Raven.extra_context metadata: Base64.decode64(params.dig(:data, :attributes, :xml))
  end
end
