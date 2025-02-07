# frozen_string_literal: true

require "uri"
require "base64"
require "pp"

class DataciteDoisController < ApplicationController
  include ActionController::MimeResponds
  include Crosscitable

  prepend_before_action :authenticate_user!
  before_action :set_include, only: %i[index show create update]
  before_action :set_raven_context, only: %i[create update validate]

  def index
    sort =
      case params[:sort]
      when "name"
        { "doi" => { order: "asc" } }
      when "-name"
        { "doi" => { order: "desc" } }
      when "created"
        { created: { order: "asc" } }
      when "-created"
        { created: { order: "desc" } }
      when "updated"
        { updated: { order: "asc" } }
      when "-updated"
        { updated: { order: "desc" } }
      when "published"
        { published: { order: "asc" } }
      when "-published"
        { published: { order: "desc" } }
      when "view-count"
        { view_count: { order: "asc" } }
      when "-view-count"
        { view_count: { order: "desc" } }
      when "download-count"
        { download_count: { order: "asc" } }
      when "-download-count"
        { download_count: { order: "desc" } }
      when "citation-count"
        { citation_count: { order: "asc" } }
      when "-citation-count"
        { citation_count: { order: "desc" } }
      when "title"
        { "primary_title.title.raw": { order: "asc" } }
      when "-title"
        { "primary_title.title.raw": { order: "desc" } }
      when "relevance"
        { "_score": { "order": "desc" } }
      else
        { updated: { order: "desc" } }
      end

    page = page_from_params(params)

    sample_group_field =
      case params[:sample_group]
      when "client"
        "client_id"
      when "data-center"
        "client_id"
      when "provider"
        "provider_id"
      when "resource-type"
        "types.resourceTypeGeneral"
      end

    # only show findable DOIs to no user, role user, and role anonymous
    if current_user.nil? || current_user.role_id == "user" || current_user.role_id == "anonymous"
      params[:state] = "findable"
    end

    # facets are enabled by default
    disable_facets = params[:disable_facets]

    # registration agencies are disabled by default
    exclude_registration_agencies = true
    if params[:include_other_registration_agencies].present?
      exclude_registration_agencies = false
    end

    if params[:id].present?
      response = DataciteDoi.find_by_id(params[:id])
    elsif params[:ids].present?
      response = DataciteDoi.find_by_ids(params[:ids], disable_facets: params[:disable_facets], facets: params[:facets], page: page, sort: sort)
    else
      response =
        DataciteDoi.query(
          params[:query],
          state: params[:state],
          exclude_registration_agencies: exclude_registration_agencies,
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
          has_organization: params[:has_organization],
          has_funder: params[:has_funder],
          link_check_status: params[:link_check_status],
          link_check_has_schema_org: params[:link_check_has_schema_org],
          link_check_body_has_pid: params[:link_check_body_has_pid],
          link_check_found_schema_org_id:
            params[:link_check_found_schema_org_id],
          link_check_found_dc_identifier:
            params[:link_check_found_dc_identifier],
          link_check_found_citation_doi: params[:link_check_found_citation_doi],
          link_check_redirect_count_gte: params[:link_check_redirect_count_gte],
          sample_group: sample_group_field,
          sample_size: params[:sample],
          source: params[:source],
          scroll_id: params[:scroll_id],
          disable_facets: disable_facets,
          facets: params[:facets],
          page: page,
          sort: sort,
          random: params[:random],
          client_type: params[:client_type],
        )
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

      # The total is just the length because for sample grouping we get everything back in one shot no pagination.

      if sample_dois
        results = sample_dois

        total = sample_dois.length
        total_pages = 1
      elsif page[:scroll].present?
        # if scroll_id has expired
        fail ActiveRecord::RecordNotFound if response.scroll_id.blank?

        results = response.results
        total = response.total
      else
        results = response.results
        total = response.results.total
        total_for_pages =
          page[:cursor].nil? ? [total.to_f, 10_000].min : total.to_f
        total_pages = page[:size] > 0 ? (total_for_pages / page[:size]).ceil : 0
      end

      if page[:scroll].present?
        options = {}
        options[:meta] = {
          total: total, "scroll-id" => response.scroll_id
        }.compact
        options[:links] = {
          self: request.original_url,
          next:
            if results.size < page[:size] || page[:size] == 0
              nil
            else
              request.base_url + "/dois?" +
                {
                  "scroll-id" => response.scroll_id,
                  "page[scroll]" => page[:scroll],
                  "page[size]" => page[:size],
                }.compact.
                to_query
            end,
        }.compact
        options[:is_collection] = true
        options[:params] = {
          current_ability: current_ability,
          detail: params[:detail],
          affiliation: params[:affiliation],
          publisher: params[:publisher],
          include_other_registration_agencies: params[:include_other_registration_agencies],
          is_collection: options[:is_collection],
        }

        # sparse fieldsets
        fields = fields_from_params(params)
        if fields
          render(
            json: DataciteDoiSerializer.new(results, options.merge(fields: fields)).serializable_hash.to_json,
            status: :ok
          )
        else
          render(
            json: DataciteDoiSerializer.new(results, options).serializable_hash.to_json,
            status: :ok
          )
        end
      else
        facets_to_facet_methods = {
          states: :facet_by_key,
          resource_types: :facet_by_combined_key,
          created: :facet_by_key_as_string,
          created_by_month: :facet_by_key_as_string,
          published: :facet_by_range,
          registered: :facet_by_key_as_string,
          providers: :facet_by_combined_key,
          clients: :facet_by_combined_key,
          client_types: :facet_by_client_type,
          affiliations: :facet_by_combined_key,
          prefixes: :facet_by_key,
          certificates: :facet_by_key,
          licenses: :facet_by_license,
          licenses_with_missing: :facet_by_license_and_other,
          schema_versions: :facet_by_schema,
          link_checks_status: :facet_by_cumulative_year,
          authors: :facet_by_authors,
          creators_and_contributors: :facet_by_creators_and_contributors,
          subjects: :facet_by_key,
          fields_of_science: :facet_by_fos,
          languages: :facet_by_language,
          registration_agencies: :facet_by_registration_agency,
          citations: :metric_facet_by_year,
          views: :metric_facet_by_year,
          downloads: :metric_facet_by_year,
          citation_count: :metric_value,
          view_count: :metric_value,
          download_count: :metric_value,
          content_url_count: :metric_value,
          open_licenses: :facet_by_combined_key,
          open_licenses_count: :metric_doc_count,
        }

        facets_to_bucket_path = {
          fields_of_science: [:subject, :buckets],
          licenses_with_missing: [],
          citation_count: [],
          view_count: [],
          download_count: [],
          content_url_count: [],
          open_licenses: [:resource_types, :buckets],
        }

        # For facets that aren't in response.aggregations,
        # define the path to the arguments to be sent to the method
        facets_to_argument_path = {
          open_licenses_count: [:open_licenses],
        }

        aggregations = response.aggregations
        facets = total == 0 ? {} :
          facets_to_facet_methods.map do |facet, method|
            if aggregations.dig(facet)
              buckets = facets_to_bucket_path.dig(facet) ? aggregations.dig(facet, *facets_to_bucket_path[facet]) : aggregations.dig(facet).buckets
              [facet.to_s.camelize(:lower), send(method, buckets)]
            elsif facets_to_argument_path.key?(facet) && aggregations.dig(*facets_to_argument_path[facet])
              argument = aggregations.dig(*facets_to_argument_path[facet])
              [facet.to_s.camelize(:lower), send(method, argument)]
            end
          end.compact.to_h

        respond_to do |format|
          format.json do
            options = {}
            options[:meta] = {
              total: total,
              "totalPages" => total_pages,
              page:
                if page[:cursor].nil? && page[:number].present?
                  page[:number]
                end
              }.merge(facets).compact

            options[:links] = {
              self: request.original_url,
              next:
                if results.size < page[:size] || page[:size] == 0 || page[:number] == total_pages
                  nil
                else
                  request.base_url + "/dois?" +
                    {
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
                      "disable-facets" => params[:disable_facets],
                      "facets" => params[:facets],
                      detail: params[:detail],
                      composite: params[:composite],
                      affiliation: params[:affiliation],
                      publisher: params[:publisher],
                      # The cursor link should be an array of values, but we want to encode it into a single string for the URL
                      "page[cursor]" =>
                        page[:cursor] ? make_cursor(results) : nil,
                      "page[number]" =>
                        if page[:cursor].nil? && page[:number].present?
                          page[:number] + 1
                        end,
                      "page[size]" => page[:size],
                      fields: fields_hash_from_params(params)
                    }.compact.
                    to_query
                end,
            }.compact
            options[:include] = @include
            options[:is_collection] = true
            options[:params] = {
              current_ability: current_ability,
              detail: params[:detail],
              composite: params[:composite],
              affiliation: params[:affiliation],
              publisher: params[:publisher],
              include_other_registration_agencies: params[:include_other_registration_agencies],
              is_collection: options[:is_collection],
            }

            # sparse fieldsets
            fields = fields_from_params(params)
            if fields
              render(
                json: DataciteDoiSerializer.new(results, options.merge(fields: fields)).serializable_hash.to_json,
                status: :ok
              )
            else
              render(
                json: DataciteDoiSerializer.new(results, options).serializable_hash.to_json,
                status: :ok
              )
            end
          end

          format.citation do
            # fetch formatted citations
            render citation: response.records.to_a,
                   style: params[:style] || "apa",
                   locale: params[:locale] || "en-US"
          end
          header = %w[
            doi
            url
            registered
            state
            resourceTypeGeneral
            resourceType
            title
            author
            publisher
            publicationYear
          ]
          format.any(
            :bibtex,
            :citeproc,
            :codemeta,
            :crosscite,
            :datacite,
            :datacite_json,
            :jats,
            :ris,
            :schema_org,
          ) { render request.format.to_sym => response.records.to_a }
          format.csv do
            render request.format.to_sym => response.records.to_a,
                   header: header
          end
        end
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      message =
        JSON.parse(e.message[6..-1]).to_h.dig(
          "error",
          "root_cause",
          0,
          "reason",
        )

      render json: { "errors" => { "title" => message } }.to_json,
             status: :bad_request
    end
  end

  def show
    # only show findable DataCite DOIs to anonymous users and role user
    # use current_user role to determine permissions to access draft and registered dois
    # instead of using ability
    # response = DataciteDoi.find_by_id(params[:id])
    # workaround until STI is enabled
    doi = DataciteDoi.where(type: "DataciteDoi").where(doi: params[:id]).first
    if doi.blank? ||
        (
          doi.aasm_state != "findable" &&
            not_allowed_by_doi_and_user(doi: doi, user: current_user)
        )
      fail ActiveRecord::RecordNotFound
    end

    respond_to do |format|
      format.json do
        # doi = response.results.first
        if not_allowed_by_doi_and_user(doi: doi, user: current_user)
          fail ActiveRecord::RecordNotFound
        end

        options = {}
        options[:include] = @include
        options[:is_collection] = false
        options[:params] = {
          current_ability: current_ability,
          detail: true,
          composite: nil,
          affiliation: params[:affiliation],
          publisher: params[:publisher],
          include_other_registration_agencies: params[:include_other_registration_agencies],
        }

        render(
          json: DataciteDoiSerializer.new(doi, options).serializable_hash.to_json,
          status: :ok
        )
      end

      # doi = response.records.first
      if not_allowed_by_doi_and_user(doi: doi, user: current_user)
        fail ActiveRecord::RecordNotFound
      end

      format.citation do
        # fetch formatted citation
        render citation: doi,
               style: params[:style] || "apa",
               locale: params[:locale] || "en-US"
      end
      header = %w[
        doi
        url
        registered
        state
        resourceTypeGeneral
        resourceType
        title
        author
        publisher
        publicationYear
      ]
      format.any(
        :bibtex,
        :citeproc,
        :codemeta,
        :crosscite,
        :datacite,
        :datacite_json,
        :jats,
        :ris,
        :schema_org,
      ) { render request.format.to_sym => doi }
      format.csv { render request.format.to_sym => doi, header: header }
    end
  end

  def validate
    @doi = DataciteDoi.new(sanitized_params.merge(only_validate: true))
    authorize! :validate, @doi

    if @doi.valid?
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = {
        current_ability: current_ability,
        affiliation: params[:affiliation],
        publisher: params[:publisher],
        include_other_registration_agencies: params[:include_other_registration_agencies],
      }

      render(
        json: DataciteDoiSerializer.new(@doi, options).serializable_hash.to_json,
        status: :ok
      )
    else
      render json: serialize_errors(@doi.errors, uid: @doi.uid), status: :ok
    end
  end

  def create
    fail CanCan::AuthorizationNotPerformed if current_user.blank?

    @doi = DataciteDoi.new(sanitized_params)

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
        affiliation: params[:affiliation],
        publisher: params[:publisher],
        include_other_registration_agencies: params[:include_other_registration_agencies],
      }

      render(
        json: DataciteDoiSerializer.new(@doi, options).serializable_hash.to_json,
        status: :created,
        location: @doi
      )
    else
      render json: serialize_errors(@doi.errors, uid: @doi.uid),
             include: @include,
             status: :unprocessable_entity
    end
  end

  def update
    @doi = DataciteDoi.where(doi: params[:id]).first
    exists = @doi.present?

    # capture username and password for reuse in the handle system

    if exists
      @doi.current_user = current_user

      if params.dig(:data, :attributes, :mode) == "transfer"
        # only update client_id

        authorize! :transfer, @doi
        @doi.assign_attributes(sanitized_params.slice(:client_id))
      else
        authorize! :update, @doi
        if sanitized_params[:schema_version].blank?
          @doi.assign_attributes(
            sanitized_params.except(:doi, :client_id).merge(
              schema_version: @doi[:schema_version] || LAST_SCHEMA_VERSION,
            ),
          )
        else
          @doi.assign_attributes(sanitized_params.except(:doi, :client_id))
        end
      end
    else
      doi_id = validate_doi(params[:id])
      fail ActiveRecord::RecordNotFound if doi_id.blank?

      @doi = DataciteDoi.new(sanitized_params.merge(doi: doi_id))
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
        publisher: params[:publisher],
        include_other_registration_agencies: params[:include_other_registration_agencies],
      }

      render(
        json: DataciteDoiSerializer.new(@doi, options).serializable_hash.to_json,
        status: exists ? :ok : :created
      )
    else
      render json: serialize_errors(@doi.errors, uid: @doi.uid),
             include: @include,
             status: :unprocessable_entity
    end
  end

  def undo
    @doi = DataciteDoi.where(doi: sanitized_params[:doi]).first
    fail ActiveRecord::RecordNotFound if @doi.blank?

    authorize! :undo, @doi

    if @doi.audits.last.undo
      options = {}
      options[:include] = @include
      options[:is_collection] = false
      options[:params] = { current_ability: current_ability, detail: true }

      render(
        json: DataciteDoiSerializer.new(@doi, options).serializable_hash.to_json,
        status: :ok
      )
    else
      render json: serialize_errors(@doi.errors, uid: @doi.uid),
             include: @include,
             status: :unprocessable_entity
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
        render json: serialize_errors(@doi.errors, uid: @doi.uid),
               status: :unprocessable_entity
      end
    else
      response.headers["Allow"] = "HEAD, GET, POST, PATCH, PUT, OPTIONS"
      render json: {
        errors: [{ status: "405", title: "Method not allowed" }],
      }.to_json,
             status: :method_not_allowed
    end
  end

  def random
    if params[:prefix].present?
      dois =
        generate_random_dois(
          params[:prefix],
          number: params[:number], size: params[:size],
        )
      render json: { dois: dois }.to_json
    else
      render json: {
        errors: [
          { status: "422", title: "Parameter prefix is required" },
        ],
      }.to_json,
             status: :unprocessable_entity
    end
  end

  def get_url
    @doi = DataciteDoi.where(doi: params[:id]).first
    fail ActiveRecord::RecordNotFound if @doi.blank?

    authorize! :get_url, @doi

    if !@doi.is_registered_or_findable? ||
        %w[europ].include?(@doi.provider_id) ||
        @doi.type == "OtherDoi"
      url = @doi.url
      head :no_content && return if url.blank?
    else
      response = @doi.get_url

      if response.status == 200
        url = response.body.dig("data", "values", 0, "data", "value")
      elsif response.status == 400 &&
          response.body.dig("errors", 0, "title", "responseCode") == 301
        response =
          OpenStruct.new(
            status: 403,
            body: {
              "errors" => [
                {
                  "status" => 403,
                  "title" => "SERVER NOT RESPONSIBLE FOR HANDLE",
                },
              ],
            },
          )
        url = nil
      else
        url = nil
      end
    end

    if url.present?
      render json: { url: url }.to_json, status: :ok
    else
      render json: response.body.to_json,
             status: response.status || :bad_request
    end
  end

  def get_dois
    authorize! :get_urls, Doi

    client =
      Client.where("datacentre.symbol = ?", current_user.uid.upcase).first
    client_prefix = client.prefixes.first
    head :no_content && return if client_prefix.blank?

    dois =
      DataciteDoi.get_dois(
        prefix: client_prefix.uid,
        username: current_user.uid.upcase,
        password: current_user.password,
      )
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
    render json: { message: "Not Implemented." }.to_json,
           status: :not_implemented
  end

  protected
    def set_include
      if params[:include].present?
        @include =
          params[:include].split(",").map { |i| i.downcase.underscore.to_sym }
        @include = @include & %i[client media]
      else
        @include = []
      end
    end

  private
    def safe_params
      if params[:data].blank?
        fail JSON::ParserError,
             "You need to provide a payload following the JSONAPI spec"
      end

      # alternateIdentifiers as alias for identifiers
      # easier before strong_parameters are checked
      if params.dig(:data, :attributes).present? &&
          !params.dig(:data, :attributes)&.key?(:identifiers) &&
          params.dig(:data, :attributes)&.key?(:alternateIdentifiers)

        alternate_identifiers = params.dig(:data, :attributes, :alternateIdentifiers)

        params[:data][:attributes][:identifiers] =
          alternate_identifiers.nil? ? nil :
            Array.wrap(alternate_identifiers).map do |a|
              if a.respond_to?(:fetch)
                {
                  identifier: a.fetch(:alternateIdentifier),
                  identifierType: a.fetch(:alternateIdentifierType),
                }
              else
                a
              end
            end
      end

      ParamsSanitizer.sanitize_nameIdentifiers(params[:creators])
      ParamsSanitizer.sanitize_nameIdentifiers(params[:contributors])

      p =
        params.require(:data).permit(
          :type,
          :id,
          attributes: ParamsSanitizer::ATTRIBUTES_MAP,
          relationships: ParamsSanitizer::RELATIONSHIPS_MAP,
        ).
          reverse_merge(ParamsSanitizer::DEFAULTS_MAP)
      client_id =
      p.dig("relationships", "client", "data", "id") ||
      current_user.try(:client_id)
      p = p.fetch("attributes").merge(client_id: client_id)
      p
    end

    def sanitized_params
      ParamsSanitizer.new(safe_params.to_h).cleanse
    end

    def set_raven_context
      return nil if params.dig(:data, :attributes, :xml).blank?

      Raven.extra_context metadata:
                            Base64.decode64(params.dig(:data, :attributes, :xml))
    end
end
