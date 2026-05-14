# frozen_string_literal: true

class EnrichedDoi < Doi
  include Elasticsearch::Model

  # if Rails.env.test?
  #   index_name("enriched_dois-test#{ENV['TEST_ENV_NUMBER']}")
  # elsif ENV["ES_PREFIX"].present?
  #   index_name("enriched_dois-#{ENV['ES_PREFIX']}")
  # else
  #   index_name("enriched_dois")
  # end
  if ENV["ES_PREFIX"].present?
    index_name("enriched_dois-#{ENV['ES_PREFIX']}")
  else
    index_name("enriched_dois")
  end

  def self.search_indices
    # if Rails.env.test?
    #   ["dois-test#{ENV['TEST_ENV_NUMBER']}", "enriched_dois-test#{ENV['TEST_ENV_NUMBER']}"]
    # elsif ENV["ES_PREFIX"].present?
    #   ["dois-#{ENV['ES_PREFIX']}", "enriched_dois-#{ENV['ES_PREFIX']}"]
    # else
    #   ["dois", "enriched_dois"]
    # end
    if ENV["ES_PREFIX"].present?
      ["dois-#{ENV['ES_PREFIX']}", "enriched_dois-#{ENV['ES_PREFIX']}"]
    else
      ["dois", "enriched_dois"]
    end
  end

  def self.enriched_search_query(query, options = {})
    # support scroll api
    # map function is small performance hit
    if options[:scroll_id].present? && options.dig(:page, :scroll)
      begin
        response = __elasticsearch__.client.scroll(body:
          { scroll_id: options[:scroll_id],
            scroll: options.dig(:page, :scroll) })
        return Hashie::Mash.new(
          total: response.dig("hits", "total", "value"),
          results: response.dig("hits", "hits").map { |r| r["_source"] },
          scroll_id: response["_scroll_id"],
        )
      # handle expired scroll_id (Elasticsearch returns this error)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return Hashie::Mash.new(
          total: 0,
          results: [],
          scroll_id: nil,
        )
      end
    end

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 25

    aggregations = if options[:totals_agg] == "provider"
      provider_aggregations
    elsif options[:totals_agg] == "client"
      client_aggregations
    elsif options[:totals_agg] == "client_export"
      client_export_aggregations
    elsif options[:totals_agg] == "prefix"
      prefix_aggregations
    elsif options[:client_type] == "igsnCatalog"
      query_aggregations(disable_facets: options[:disable_facets], facets: options[:facets]).merge(self.igsn_id_catalog_aggregations)
    else
      query_aggregations(disable_facets: options[:disable_facets], facets: options[:facets])
    end

    # Cursor nav uses search_after, this should always be an array of values that match the sort.
    if options.fetch(:page, {}).key?(:cursor)
      # make sure we have a valid cursor
      cursor = [0, ""]
      if options.dig(:page, :cursor).is_a?(Array)
        timestamp, uid = options.dig(:page, :cursor)
        cursor = [timestamp.to_i, uid.to_s]
      elsif options.dig(:page, :cursor).is_a?(String)
        timestamp, uid = options.dig(:page, :cursor).split(",")
        cursor = [timestamp.to_i, uid.to_s]
      end

      from = 0
      search_after = cursor
      sort = [{ created: "asc", uid: "asc" }]
    else
      from = ((options.dig(:page, :number) || 1) - 1) * (options.dig(:page, :size) || 25)
      search_after = nil
      sort = options[:sort]
    end

    # make sure field name uses underscore
    # escape forward slash, but not other Elasticsearch special characters
    if query.present?
      query = query.gsub(/publicationYear/, "publication_year")
      query = query.gsub(/relatedIdentifiers/, "related_identifiers")
      query = query.gsub(/relatedItems/, "related_items")
      query = query.gsub(/rightsList/, "rights_list")
      query = query.gsub(/fundingReferences/, "funding_references")
      query = query.gsub(/geoLocations/, "geo_locations")
      query = query.gsub(/version:/, "version_info:")
      query = query.gsub(/landingPage/, "landing_page")
      query = query.gsub(/contentUrl/, "content_url")
      query = query.gsub(/citationCount/, "citation_count")
      query = query.gsub(/viewCount/, "view_count")
      query = query.gsub(/downloadCount/, "download_count")
      query = query.gsub(/(publisher\.)(name|publisherIdentifier|publisherIdentifierScheme|schemeUri|lang)/, 'publisher_obj.\2')
      query = query.gsub(/schemaVersion/, "schema_version")
      query = query.gsub("/", "\\/")
    end

    # turn ids into an array if provided as comma-separated string
    options[:ids] = options[:ids].split(",") if options[:ids].is_a?(String)

    if query.present?
      must = [{ query_string: { query: query, fields: query_fields, default_operator: "AND", phrase_slop: 1 } }]
    else
      must = [{ match_all: {} }]
    end

    must_not = []
    filter = []
    should = []
    minimum_should_match = 0

    # If a DOI has enrichments it will be in the enriched_dois index, if it doesn't it will be in the dois index,
    # so we need to search both and combine results. The filter below ensures we get results from both indices
    # but don't get duplicates of DOIs that have enrichments (i.e. if a DOI has an enrichment it will only return
    # the enriched version from the enriched_dois index, not the non-enriched version from the dois index).
    filter << {
      bool: {
        should: [
          { term: { "_index": index_name } },
          {
            bool: {
              must: [
                { term: { "_index": Doi.index_name } }
              ],
              must_not: [
                { term: { has_enrichments: true } }
              ]
            }
          }
        ],
        minimum_should_match: 1
      }
    }

    filter << { terms: { doi: options[:ids].map(&:upcase) } } if options[:ids].present?
    if options[:resource_type_id].present?
      resource_type_ids = options[:resource_type_id]
                            .split(",")
                            .map { |id| id.strip.underscore.dasherize }
      filter << { terms: { resource_type_id: resource_type_ids } }
    end
    filter << { terms: { "types.resourceType": options[:resource_type].split(",") } } if options[:resource_type].present?
    if options[:provider_id].present?
      options[:provider_id].split(",").each { |id|
        should << { term: { "provider_id": { value: id, case_insensitive: true } } }
      }
      minimum_should_match = 1
    end
    if options[:client_id].present?
      options[:client_id].split(",").each { |id|
        should << { term: { "client_id": { value: id, case_insensitive: true } } }
      }
      minimum_should_match = 1
    end
    filter << { terms: { agency: options[:agency].split(",").map(&:downcase) } } if options[:agency].present?
    filter << { terms: { prefix: options[:prefix].to_s.split(",") } } if options[:prefix].present?
    filter << { terms: { language: options[:language].to_s.split(",").map(&:downcase) } } if options[:language].present?
    filter << { term: { uid: options[:uid] } } if options[:uid].present?
    filter << { range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } } if options[:created].present?
    filter << { range: { publication_year: { gte: "#{options[:published].split(',').min}||/y", lte: "#{options[:published].split(',').max}||/y", format: "yyyy" } } } if options[:published].present?
    filter << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" } } if options[:schema_version].present?
    filter << { terms: { "subjects.subject.keyword": options[:subject].split(",") } } if options[:subject].present?
    if options[:pid_entity].present?
      filter << { term: { "subjects.subjectScheme": "PidEntity" } }
      filter << { terms: { "subjects.subject.keyword": options[:pid_entity].split(",").map(&:humanize) } }
    end
    if options[:field_of_science].present?
      filter << { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } }
      filter << { terms: { "subjects.subject.keyword": options[:field_of_science].split(",").map { |s| "FOS: " + s.humanize } } }
    end
    if options[:field_of_science_repository].present?
      filter << { terms: { "fields_of_science_repository": options[:field_of_science_repository].split(",").map { |s| s.humanize } } }
    end
    if options[:field_of_science_combined].present?
      filter << { terms: { "fields_of_science_combined": options[:field_of_science_combined].split(",").map { |s| s.humanize } } }
    end
    filter << { terms: { "rights_list.rightsIdentifier" => options[:license].split(",") } } if options[:license].present?
    filter << { term: { source: options[:source] } } if options[:source].present?
    filter << { range: { reference_count: { "gte": options[:has_references].to_i } } } if options[:has_references].present?
    filter << { range: { citation_count: { "gte": options[:has_citations].to_i } } } if options[:has_citations].present?
    filter << { range: { part_count: { "gte": options[:has_parts].to_i } } } if options[:has_parts].present?
    filter << { range: { part_of_count: { "gte": options[:has_part_of].to_i } } } if options[:has_part_of].present?
    filter << { range: { version_count: { "gte": options[:has_versions].to_i } } } if options[:has_versions].present?
    filter << { range: { version_of_count: { "gte": options[:has_version_of].to_i } } } if options[:has_version_of].present?
    filter << { range: { view_count: { "gte": options[:has_views].to_i } } } if options[:has_views].present?
    filter << { range: { download_count: { "gte": options[:has_downloads].to_i } } } if options[:has_downloads].present?
    filter << { term: { "landing_page.status": options[:link_check_status] } } if options[:link_check_status].present?
    filter << { exists: { field: "landing_page.checked" } } if options[:link_checked].present?
    filter << { term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] } } if options[:link_check_has_schema_org].present?
    filter << { term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] } } if options[:link_check_body_has_pid].present?
    filter << { exists: { field: "landing_page.schemaOrgId" } } if options[:link_check_found_schema_org_id].present?
    filter << { exists: { field: "landing_page.dcIdentifier" } } if options[:link_check_found_dc_identifier].present?
    filter << { exists: { field: "landing_page.citationDoi" } } if options[:link_check_found_citation_doi].present?
    filter << { range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } } if options[:link_check_redirect_count_gte].present?
    filter << { terms: { aasm_state: options[:state].to_s.split(",") } } if options[:state].present?
    filter << { range: { registered: { gte: "#{options[:registered].split(',').min}||/y", lte: "#{options[:registered].split(',').max}||/y", format: "yyyy" } } } if options[:registered].present?
    filter << { term: { "consortium_id": { value: options[:consortium_id], case_insensitive: true  } } } if options[:consortium_id].present?
    # TODO align PID parsing
    filter << { term: { "client.re3data_id" => doi_from_url(options[:re3data_id]) } } if options[:re3data_id].present?
    filter << { term: { "client.opendoar_id" => options[:opendoar_id] } } if options[:opendoar_id].present?
    filter << { terms: { "client.certificate" => options[:certificate].split(",") } } if options[:certificate].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" } } if options[:user_id].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ORCID" } } if options[:has_person].present?
    filter << { term: { "client.client_type" =>  options[:client_type] } } if options[:client_type]
    filter << { term: { "types.resourceTypeGeneral" => "PhysicalObject" } } if options[:client_type] == "igsnCatalog"

    if options[:funded_by].present?
      normalized_funder = "https://#{ror_from_url(options[:funded_by])}"
      if options[:include_funder_child_organizations] == "true"
        filter << {
          bool: {
            should: [
              { term: { "funder_rors": normalized_funder } },
              { term: { "funder_parent_rors": normalized_funder } }
            ],
            minimum_should_match: 1
          }
        }
      else
        filter << { term: { "funder_rors": normalized_funder } }
      end
    end
    # match either one of has_affiliation, has_organization, or has_funder
    if options[:has_organization].present?
      should << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
      should << { term: { "contributors.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
      minimum_should_match = 1
    end
    if options[:has_affiliation].present?
      should << { term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" } }
      should << { term: { "contributors.affiliation.affiliationIdentifierScheme" => "ROR" } }
      minimum_should_match = 1
    end
    if options[:has_funder].present?
      should << { term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" } }
      minimum_should_match = 1
    end
    if options[:has_member].present?
      should << { exists: { field: "provider.ror_id" } }
      minimum_should_match = 1
    end

    # match either ROR ID or Crossref Funder ID if either organization_id, affiliation_id,
    # funder_id or member_id is a query parameter
    if options[:organization_id].present?
      # should << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
      # should << { term: { "contributors.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
      should << { term: { "organization_id" => ror_from_url(options[:organization_id]) } }
      minimum_should_match = 1
    end
    if options[:affiliation_id].present?
      should << { term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) } }
      minimum_should_match = 1
    end
    if options[:funder_id].present?
      should << { terms: { "funding_references.funderIdentifier" => options[:funder_id].split(",").map { |f| "https://doi.org/#{doi_from_url(f)}" } } }
      minimum_should_match = 1
    end
    if options[:member_id].present?
      should << { term: { "provider.ror_id" => "https://#{ror_from_url(options[:member_id])}" } }
      minimum_should_match = 1
    end

    if options[:affiliation_country].present?
      country_codes = options[:affiliation_country]
                        .split(",")
                        .map { |c| c.strip.upcase }
                        .reject(&:blank?)
      filter << { terms: { "affiliation_countries" => country_codes } } if country_codes.any?
    end

    must_not << { terms: { agency: ["crossref", "kisti", "medra", "jalc", "istic", "airiti", "cnki", "op"] } } if options[:exclude_registration_agencies]

    # ES query can be optionally defined in different ways
    # So here we build it differently based upon options
    # This is mostly useful when trying to wrap it in a function_score query
    es_query = {}

    # The main bool query with filters
    bool_query = {
      must: must,
      must_not: must_not,
      filter: filter,
      should: should,
      minimum_should_match: minimum_should_match,
    }

    # Function score is used to provide varying score to return different values
    # We use the bool query above as our principle query
    # Then apply additional function scoring as appropriate
    # Note this can be performance intensive.
    function_score = {
      query: {
        bool: bool_query,
      },
      random_score: {
        "seed": "random_#{rand(1...100000)}",
      },
    }

    if options[:random].present? && options[:random].to_s.downcase == "true"  # .present? will always be true even if "false" is the value, because strings are truthy
      # Random results and cursor pagination are incompatible (https://github.com/datacite/lupo/issues/838), throw an error if attempted
      if options.fetch(:page, {}).key?(:cursor)
        fail ActionController::BadRequest, "Cursor-based pagination and random sampling are mutually exclusive, please choose one or the other."
      end
      es_query["function_score"] = function_score
      # Don't do any sorting for random results
      sort = nil
    else
      es_query["bool"] = bool_query
    end

    # Sample grouping is optional included aggregation
    if options[:sample_group].present?
      aggregations[:samples] = {
        terms: {
          field: options[:sample_group],
          size: 10000,
        },
        aggs: {
          "samples_hits": {
            top_hits: {
              size: options[:sample_size].presence || 1,
            },
          },
        },
      }
    end

    # three options for going through results are scroll, cursor and pagination
    # the default is pagination
    # scroll is triggered by the page[scroll] query parameter
    # cursor is triggered by the page[cursor] query parameter

    # can't use search wrapper function for scroll api
    # map function for scroll is small performance hit
    indices = search_indices

    if options.dig(:page, :scroll).present?
      response = __elasticsearch__.client.search(
        index: indices,
        scroll: options.dig(:page, :scroll),
        body: {
          size: options.dig(:page, :size),
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true,
        }.compact,
      )
      Hashie::Mash.new(
        total: response.dig("hits", "total", "value"),
        results: response.dig("hits", "hits").map do |r|
          {
            index: r["_index"],
            id: r["_id"],
            source: r["_source"],
            sort: r["sort"],
          }
        end,
        scroll_id: response["_scroll_id"],
      )
    elsif options.fetch(:page, {}).key?(:cursor)
      response = __elasticsearch__.client.search(
        index: indices,
        body: {
          size: options.dig(:page, :size),
          search_after: search_after,
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true,
        }.compact,
      )

      Hashie::Mash.new(
        total: response.dig("hits", "total", "value"),
        results: response.dig("hits", "hits").map do |r|
          {
            index: r["_index"],
            id: r["_id"],
            source: r["_source"],
            sort: r["sort"],
          }
        end,
        aggregations: Hashie::Mash.new(response["aggregations"] || {}),
      )
    else
      response = __elasticsearch__.client.search(
        index: indices,
        body: {
          size: options.dig(:page, :size),
          from: from,
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true,
        }.compact,
      )

      Hashie::Mash.new(
        total: response.dig("hits", "total", "value"),
        results: response.dig("hits", "hits").map do |r|
          {
            index: r["_index"],
            id: r["_id"],
            source: r["_source"],
            sort: r["sort"],
          }
        end,
        aggregations: Hashie::Mash.new(response["aggregations"] || {}),
      )
    end
  end
end
