# frozen_string_literal: true

class EnrichedDoi < Doi
  include Elasticsearch::Model

  attr_accessor :indexed_enrichment_uuids, :indexed_has_enrichments

  if Rails.env.test?
    index_name("enriched_dois-test#{ENV['TEST_ENV_NUMBER']}")
  elsif ENV["ES_PREFIX"].present?
    index_name("enriched_dois-#{ENV['ES_PREFIX']}")
  else
    index_name("enriched_dois")
  end

  def self.search_indices
    if Rails.env.test?
      ["dois-test#{ENV['TEST_ENV_NUMBER']}", "enriched_dois-test#{ENV['TEST_ENV_NUMBER']}"]
    elsif ENV["ES_PREFIX"].present?
      ["dois-#{ENV['ES_PREFIX']}", "enriched_dois-#{ENV['ES_PREFIX']}"]
    else
      ["dois", "enriched_dois"]
    end
  end

  def has_enrichments
    return indexed_has_enrichments unless indexed_has_enrichments.nil?

    super
  end

  def enrichment_uuids
    return indexed_enrichment_uuids unless indexed_enrichment_uuids.nil?

    super
  end

  # Faster
  def self.enriched_search_query(query, options = {})
    if options[:scroll_id].present? && options.dig(:page, :scroll)
      begin
        response = __elasticsearch__.client.scroll(
          body: {
            scroll_id: options[:scroll_id],
            scroll: options.dig(:page, :scroll),
          }
        )

        return Hashie::Mash.new(
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

    aggregations =
      if options[:totals_agg] == "provider"
        provider_aggregations
      elsif options[:totals_agg] == "client"
        client_aggregations
      elsif options[:totals_agg] == "client_export"
        client_export_aggregations
      elsif options[:totals_agg] == "prefix"
        prefix_aggregations
      elsif options[:client_type] == "igsnCatalog"
        query_aggregations(
          disable_facets: options[:disable_facets],
          facets: options[:facets],
        ).merge(self.igsn_id_catalog_aggregations)
      else
        query_aggregations(
          disable_facets: options[:disable_facets],
          facets: options[:facets],
        )
      end

    if options.fetch(:page, {}).key?(:cursor)
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
      sort = [{ created: "asc" }, { uid: "asc" }]
    else
      from = ((options.dig(:page, :number) || 1) - 1) * (options.dig(:page, :size) || 25)
      search_after = nil
      sort = Array.wrap(options[:sort] || { updated: { order: "desc" } })
    end

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
      query = query.gsub(
        /(publisher\.)(name|publisherIdentifier|publisherIdentifierScheme|schemeUri|lang)/,
        'publisher_obj.\2'
      )
      query = query.gsub(/schemaVersion/, "schema_version")
      query = query.gsub("/", "\\/")
    end

    options[:ids] = options[:ids].split(",") if options[:ids].is_a?(String)

    must =
      if query.present?
        [
          {
            query_string: {
              query: query,
              fields: query_fields,
              default_operator: "AND",
              phrase_slop: 1,
            },
          },
        ]
      else
        [{ match_all: {} }]
      end

    must_not = []
    filter = []
    should = []
    minimum_should_match = 0

    filter << ({ terms: { doi: options[:ids].map(&:upcase) } }) if options[:ids].present?

    if options[:resource_type_id].present?
      resource_type_ids = options[:resource_type_id]
                            .split(",")
                            .map { |id| id.strip.underscore.dasherize }
      filter << ({ terms: { resource_type_id: resource_type_ids } })
    end

    filter << ({ terms: { "types.resourceType": options[:resource_type].split(",") } }) if options[:resource_type].present?

    if options[:provider_id].present?
      options[:provider_id].split(",").each do |id|
        should << ({ term: { "provider_id": { value: id, case_insensitive: true } } })
      end
      minimum_should_match = 1
    end

    if options[:client_id].present?
      options[:client_id].split(",").each do |id|
        should << ({ term: { "client_id": { value: id, case_insensitive: true } } })
      end
      minimum_should_match = 1
    end

    filter << ({ terms: { agency: options[:agency].split(",").map(&:downcase) } }) if options[:agency].present?
    filter << ({ terms: { prefix: options[:prefix].to_s.split(",") } }) if options[:prefix].present?
    filter << ({ terms: { language: options[:language].to_s.split(",").map(&:downcase) } }) if options[:language].present?
    filter << ({ term: { uid: options[:uid] } }) if options[:uid].present?
    filter << ({ range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } }) if options[:created].present?
    filter << ({ range: { publication_year: { gte: "#{options[:published].split(',').min}||/y", lte: "#{options[:published].split(',').max}||/y", format: "yyyy" } } }) if options[:published].present?
    filter << ({ term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" } }) if options[:schema_version].present?
    filter << ({ terms: { "subjects.subject.keyword": options[:subject].split(",") } }) if options[:subject].present?

    if options[:pid_entity].present?
      filter << ({ term: { "subjects.subjectScheme": "PidEntity" } })
      filter << ({ terms: { "subjects.subject.keyword": options[:pid_entity].split(",").map(&:humanize) } })
    end

    if options[:field_of_science].present?
      filter << ({ term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } })
      filter << ({ terms: { "subjects.subject.keyword": options[:field_of_science].split(",").map { |s| "FOS: " + s.humanize } } })
    end

    if options[:field_of_science_repository].present?
      filter << ({ terms: { "fields_of_science_repository": options[:field_of_science_repository].split(",").map { |s| s.humanize } } })
    end

    if options[:field_of_science_combined].present?
      filter << ({ terms: { "fields_of_science_combined": options[:field_of_science_combined].split(",").map { |s| s.humanize } } })
    end

    filter << ({ terms: { "rights_list.rightsIdentifier" => options[:license].split(",") } }) if options[:license].present?
    filter << ({ term: { source: options[:source] } }) if options[:source].present?
    filter << ({ range: { reference_count: { "gte": options[:has_references].to_i } } }) if options[:has_references].present?
    filter << ({ range: { citation_count: { "gte": options[:has_citations].to_i } } }) if options[:has_citations].present?
    filter << ({ range: { part_count: { "gte": options[:has_parts].to_i } } }) if options[:has_parts].present?
    filter << ({ range: { part_of_count: { "gte": options[:has_part_of].to_i } } }) if options[:has_part_of].present?
    filter << ({ range: { version_count: { "gte": options[:has_versions].to_i } } }) if options[:has_versions].present?
    filter << ({ range: { version_of_count: { "gte": options[:has_version_of].to_i } } }) if options[:has_version_of].present?
    filter << ({ range: { view_count: { "gte": options[:has_views].to_i } } }) if options[:has_views].present?
    filter << ({ range: { download_count: { "gte": options[:has_downloads].to_i } } }) if options[:has_downloads].present?
    filter << ({ term: { "landing_page.status": options[:link_check_status] } }) if options[:link_check_status].present?
    filter << ({ exists: { field: "landing_page.checked" } }) if options[:link_checked].present?
    filter << ({ term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] } }) if options[:link_check_has_schema_org].present?
    filter << ({ term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] } }) if options[:link_check_body_has_pid].present?
    filter << ({ exists: { field: "landing_page.schemaOrgId" } }) if options[:link_check_found_schema_org_id].present?
    filter << ({ exists: { field: "landing_page.dcIdentifier" } }) if options[:link_check_found_dc_identifier].present?
    filter << ({ exists: { field: "landing_page.citationDoi" } }) if options[:link_check_found_citation_doi].present?
    filter << ({ range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } }) if options[:link_check_redirect_count_gte].present?
    filter << ({ terms: { aasm_state: options[:state].to_s.split(",") } }) if options[:state].present?
    filter << ({ range: { registered: { gte: "#{options[:registered].split(',').min}||/y", lte: "#{options[:registered].split(',').max}||/y", format: "yyyy" } } }) if options[:registered].present?
    filter << ({ term: { "consortium_id": { value: options[:consortium_id], case_insensitive: true } } }) if options[:consortium_id].present?
    filter << ({ term: { "client.re3data_id" => doi_from_url(options[:re3data_id]) } }) if options[:re3data_id].present?
    filter << ({ term: { "client.opendoar_id" => options[:opendoar_id] } }) if options[:opendoar_id].present?
    filter << ({ terms: { "client.certificate" => options[:certificate].split(",") } }) if options[:certificate].present?
    filter << ({ term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" } }) if options[:user_id].present?
    filter << ({ term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ORCID" } }) if options[:has_person].present?
    filter << ({ term: { "client.client_type" => options[:client_type] } }) if options[:client_type]
    filter << ({ term: { "types.resourceTypeGeneral" => "PhysicalObject" } }) if options[:client_type] == "igsnCatalog"

    if options[:funded_by].present?
      normalized_funder = "https://#{ror_from_url(options[:funded_by])}"
      if options[:include_funder_child_organizations] == "true"
        filter << ({
          bool: {
            should: [
              { term: { "funder_rors": normalized_funder } },
              { term: { "funder_parent_rors": normalized_funder } }
            ],
            minimum_should_match: 1
          }
        })
      else
        filter << ({ term: { "funder_rors": normalized_funder } })
      end
    end

    if options[:has_organization].present?
      should << ({ term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ROR" } })
      should << ({ term: { "contributors.nameIdentifiers.nameIdentifierScheme" => "ROR" } })
      minimum_should_match = 1
    end

    if options[:has_affiliation].present?
      should << ({ term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" } })
      should << ({ term: { "contributors.affiliation.affiliationIdentifierScheme" => "ROR" } })
      minimum_should_match = 1
    end

    if options[:has_funder].present?
      should << ({ term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" } })
      minimum_should_match = 1
    end

    if options[:has_member].present?
      should << ({ exists: { field: "provider.ror_id" } })
      minimum_should_match = 1
    end

    if options[:organization_id].present?
      should << ({ term: { "organization_id" => ror_from_url(options[:organization_id]) } })
      minimum_should_match = 1
    end

    if options[:affiliation_id].present?
      should << ({ term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) } })
      minimum_should_match = 1
    end

    if options[:funder_id].present?
      should << ({ terms: { "funding_references.funderIdentifier" => options[:funder_id].split(",").map { |f| "https://doi.org/#{doi_from_url(f)}" } } })
      minimum_should_match = 1
    end

    if options[:member_id].present?
      should << ({ term: { "provider.ror_id" => "https://#{ror_from_url(options[:member_id])}" } })
      minimum_should_match = 1
    end

    if options[:affiliation_country].present?
      country_codes = options[:affiliation_country]
                        .split(",")
                        .map { |c| c.strip.upcase }
                        .reject(&:blank?)
      filter << ({ terms: { "affiliation_countries" => country_codes } }) if country_codes.any?
    end

    must_not << ({ terms: { agency: ["crossref", "kisti", "medra", "jalc", "istic", "airiti", "cnki", "op"] } }) if options[:exclude_registration_agencies]

    es_query = {}

    bool_query = {
      must: must,
      must_not: must_not,
      filter: filter,
      should: should,
      minimum_should_match: minimum_should_match,
    }

    function_score = {
      query: {
        bool: bool_query,
      },
      random_score: {
        "seed": "random_#{rand(1...100000)}",
      },
    }

    if options[:random].present? && options[:random].to_s.downcase == "true"
      if options.fetch(:page, {}).key?(:cursor)
        fail ActionController::BadRequest, "Cursor-based pagination and random sampling are mutually exclusive, please choose one or the other."
      end
      es_query["function_score"] = function_score
      sort = nil
    else
      es_query["bool"] = bool_query
    end

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

    search_body = {
      size: options.dig(:page, :size) || 25,
      sort: sort,
      query: es_query,
      aggregations: aggregations,
      track_total_hits: true,
    }.compact

    search_body[:from] = from if search_after.nil? && !options.dig(:page, :scroll).present?
    search_body[:search_after] = search_after if search_after.present?

    enriched_response = __elasticsearch__.client.search(
      index: index_name,
      body: search_body,
    )

    doi_response = __elasticsearch__.client.search(
      index: Doi.index_name,
      body: search_body,
    )

    enriched_hits = enriched_response.dig("hits", "hits") || []
    doi_hits = doi_response.dig("hits", "hits") || []

    merged = {}

    enriched_hits.each do |hit|
      doi = hit.dig("_source", "doi")
      next if doi.blank?

      merged[doi] = hit
    end

    doi_hits.each do |hit|
      doi = hit.dig("_source", "doi")
      next if doi.blank?
      next if merged.key?(doi)

      merged[doi] = hit
    end

    merged_hits = merged.values

    Hashie::Mash.new(
      total: merged_hits.length,
      results: merged_hits.map do |r|
        {
          index: r["_index"],
          id: r["_id"],
          source: r["_source"],
          sort: r["sort"],
        }
      end,
      aggregations: Hashie::Mash.new(enriched_response["aggregations"] || doi_response["aggregations"] || {}),
    )
  end

  # More accurate but slower
  # def self.enriched_search_query(query, options = {})
  #   options[:page] ||= {}
  #   options[:page][:number] ||= 1
  #   options[:page][:size] ||= 25

  #   if query.present?
  #     query = query.gsub(/publicationYear/, "publication_year")
  #     query = query.gsub(/relatedIdentifiers/, "related_identifiers")
  #     query = query.gsub(/relatedItems/, "related_items")
  #     query = query.gsub(/rightsList/, "rights_list")
  #     query = query.gsub(/fundingReferences/, "funding_references")
  #     query = query.gsub(/geoLocations/, "geo_locations")
  #     query = query.gsub(/version:/, "version_info:")
  #     query = query.gsub(/landingPage/, "landing_page")
  #     query = query.gsub(/contentUrl/, "content_url")
  #     query = query.gsub(/citationCount/, "citation_count")
  #     query = query.gsub(/viewCount/, "view_count")
  #     query = query.gsub(/downloadCount/, "download_count")
  #     query = query.gsub(
  #       /(publisher\.)(name|publisherIdentifier|publisherIdentifierScheme|schemeUri|lang)/,
  #       'publisher_obj.\2'
  #     )
  #     query = query.gsub(/schemaVersion/, "schema_version")
  #     query = query.gsub("/", "\\/")
  #   end

  #   options[:ids] = options[:ids].split(",") if options[:ids].is_a?(String)

  #   must =
  #     if query.present?
  #       [
  #         {
  #           query_string: {
  #             query: query,
  #             fields: query_fields,
  #             default_operator: "AND",
  #             phrase_slop: 1,
  #           },
  #         },
  #       ]
  #     else
  #       [{ match_all: {} }]
  #     end

  #   must_not = []
  #   filter = []
  #   should = []
  #   minimum_should_match = 0

  #   filter << ({ terms: { doi: options[:ids].map(&:upcase) } }) if options[:ids].present?

  #   if options[:resource_type_id].present?
  #     resource_type_ids = options[:resource_type_id]
  #                           .split(",")
  #                           .map { |id| id.strip.underscore.dasherize }
  #     filter << ({ terms: { resource_type_id: resource_type_ids } })
  #   end

  #   filter << ({ terms: { "types.resourceType": options[:resource_type].split(",") } }) if options[:resource_type].present?

  #   if options[:provider_id].present?
  #     options[:provider_id].split(",").each do |id|
  #       should << ({ term: { "provider_id": { value: id, case_insensitive: true } } })
  #     end
  #     minimum_should_match = 1
  #   end

  #   if options[:client_id].present?
  #     options[:client_id].split(",").each do |id|
  #       should << ({ term: { "client_id": { value: id, case_insensitive: true } } })
  #     end
  #     minimum_should_match = 1
  #   end

  #   filter << ({ terms: { agency: options[:agency].split(",").map(&:downcase) } }) if options[:agency].present?
  #   filter << ({ terms: { prefix: options[:prefix].to_s.split(",") } }) if options[:prefix].present?
  #   filter << ({ terms: { language: options[:language].to_s.split(",").map(&:downcase) } }) if options[:language].present?
  #   filter << ({ term: { uid: options[:uid] } }) if options[:uid].present?
  #   filter << ({ range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } }) if options[:created].present?
  #   filter << ({ range: { publication_year: { gte: "#{options[:published].split(',').min}||/y", lte: "#{options[:published].split(',').max}||/y", format: "yyyy" } } }) if options[:published].present?
  #   filter << ({ term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" } }) if options[:schema_version].present?
  #   filter << ({ terms: { "subjects.subject.keyword": options[:subject].split(",") } }) if options[:subject].present?

  #   if options[:pid_entity].present?
  #     filter << ({ term: { "subjects.subjectScheme": "PidEntity" } })
  #     filter << ({ terms: { "subjects.subject.keyword": options[:pid_entity].split(",").map(&:humanize) } })
  #   end

  #   if options[:field_of_science].present?
  #     filter << ({ term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } })
  #     filter << ({ terms: { "subjects.subject.keyword": options[:field_of_science].split(",").map { |s| "FOS: " + s.humanize } } })
  #   end

  #   if options[:field_of_science_repository].present?
  #     filter << ({ terms: { "fields_of_science_repository": options[:field_of_science_repository].split(",").map { |s| s.humanize } } })
  #   end

  #   if options[:field_of_science_combined].present?
  #     filter << ({ terms: { "fields_of_science_combined": options[:field_of_science_combined].split(",").map { |s| s.humanize } } })
  #   end

  #   filter << ({ terms: { "rights_list.rightsIdentifier" => options[:license].split(",") } }) if options[:license].present?
  #   filter << ({ term: { source: options[:source] } }) if options[:source].present?
  #   filter << ({ range: { reference_count: { "gte": options[:has_references].to_i } } }) if options[:has_references].present?
  #   filter << ({ range: { citation_count: { "gte": options[:has_citations].to_i } } }) if options[:has_citations].present?
  #   filter << ({ range: { part_count: { "gte": options[:has_parts].to_i } } }) if options[:has_parts].present?
  #   filter << ({ range: { part_of_count: { "gte": options[:has_part_of].to_i } } }) if options[:has_part_of].present?
  #   filter << ({ range: { version_count: { "gte": options[:has_versions].to_i } } }) if options[:has_versions].present?
  #   filter << ({ range: { version_of_count: { "gte": options[:has_version_of].to_i } } }) if options[:has_version_of].present?
  #   filter << ({ range: { view_count: { "gte": options[:has_views].to_i } } }) if options[:has_views].present?
  #   filter << ({ range: { download_count: { "gte": options[:has_downloads].to_i } } }) if options[:has_downloads].present?
  #   filter << ({ term: { "landing_page.status": options[:link_check_status] } }) if options[:link_check_status].present?
  #   filter << ({ exists: { field: "landing_page.checked" } }) if options[:link_checked].present?
  #   filter << ({ term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] } }) if options[:link_check_has_schema_org].present?
  #   filter << ({ term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] } }) if options[:link_check_body_has_pid].present?
  #   filter << ({ exists: { field: "landing_page.schemaOrgId" } }) if options[:link_check_found_schema_org_id].present?
  #   filter << ({ exists: { field: "landing_page.dcIdentifier" } }) if options[:link_check_found_dc_identifier].present?
  #   filter << ({ exists: { field: "landing_page.citationDoi" } }) if options[:link_check_found_citation_doi].present?
  #   filter << ({ range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } }) if options[:link_check_redirect_count_gte].present?
  #   filter << ({ terms: { aasm_state: options[:state].to_s.split(",") } }) if options[:state].present?
  #   filter << ({ range: { registered: { gte: "#{options[:registered].split(',').min}||/y", lte: "#{options[:registered].split(',').max}||/y", format: "yyyy" } } }) if options[:registered].present?
  #   filter << ({ term: { "consortium_id": { value: options[:consortium_id], case_insensitive: true } } }) if options[:consortium_id].present?
  #   filter << ({ term: { "client.re3data_id" => doi_from_url(options[:re3data_id]) } }) if options[:re3data_id].present?
  #   filter << ({ term: { "client.opendoar_id" => options[:opendoar_id] } }) if options[:opendoar_id].present?
  #   filter << ({ terms: { "client.certificate" => options[:certificate].split(",") } }) if options[:certificate].present?
  #   filter << ({ term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" } }) if options[:user_id].present?
  #   filter << ({ term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ORCID" } }) if options[:has_person].present?
  #   filter << ({ term: { "client.client_type" => options[:client_type] } }) if options[:client_type]
  #   filter << ({ term: { "types.resourceTypeGeneral" => "PhysicalObject" } }) if options[:client_type] == "igsnCatalog"

  #   if options[:funded_by].present?
  #     normalized_funder = "https://#{ror_from_url(options[:funded_by])}"
  #     if options[:include_funder_child_organizations] == "true"
  #       filter << ({
  #         bool: {
  #           should: [
  #             { term: { "funder_rors": normalized_funder } },
  #             { term: { "funder_parent_rors": normalized_funder } }
  #           ],
  #           minimum_should_match: 1
  #         }
  #       })
  #     else
  #       filter << ({ term: { "funder_rors": normalized_funder } })
  #     end
  #   end

  #   if options[:has_organization].present?
  #     should << ({ term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ROR" } })
  #     should << ({ term: { "contributors.nameIdentifiers.nameIdentifierScheme" => "ROR" } })
  #     minimum_should_match = 1
  #   end

  #   if options[:has_affiliation].present?
  #     should << ({ term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" } })
  #     should << ({ term: { "contributors.affiliation.affiliationIdentifierScheme" => "ROR" } })
  #     minimum_should_match = 1
  #   end

  #   if options[:has_funder].present?
  #     should << ({ term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" } })
  #     minimum_should_match = 1
  #   end

  #   if options[:has_member].present?
  #     should << ({ exists: { field: "provider.ror_id" } })
  #     minimum_should_match = 1
  #   end

  #   if options[:organization_id].present?
  #     should << ({ term: { "organization_id" => ror_from_url(options[:organization_id]) } })
  #     minimum_should_match = 1
  #   end

  #   if options[:affiliation_id].present?
  #     should << ({ term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) } })
  #     minimum_should_match = 1
  #   end

  #   if options[:funder_id].present?
  #     should << ({ terms: { "funding_references.funderIdentifier" => options[:funder_id].split(",").map { |f| "https://doi.org/#{doi_from_url(f)}" } } })
  #     minimum_should_match = 1
  #   end

  #   if options[:member_id].present?
  #     should << ({ term: { "provider.ror_id" => "https://#{ror_from_url(options[:member_id])}" } })
  #     minimum_should_match = 1
  #   end

  #   if options[:affiliation_country].present?
  #     country_codes = options[:affiliation_country]
  #                       .split(",")
  #                       .map { |c| c.strip.upcase }
  #                       .reject(&:blank?)
  #     filter << ({ terms: { "affiliation_countries" => country_codes } }) if country_codes.any?
  #   end

  #   must_not << ({ terms: { agency: ["crossref", "kisti", "medra", "jalc", "istic", "airiti", "cnki", "op"] } }) if options[:exclude_registration_agencies]

  #   bool_query = {
  #     must: must,
  #     must_not: must_not,
  #     filter: filter,
  #     should: should,
  #     minimum_should_match: minimum_should_match,
  #   }

  #   es_query = {}
  #   if options[:random].present? && options[:random].to_s.downcase == "true"
  #     if options.fetch(:page, {}).key?(:cursor)
  #       fail ActionController::BadRequest, "Cursor-based pagination and random sampling are mutually exclusive, please choose one or the other."
  #     end

  #     es_query["function_score"] = {
  #       query: { bool: bool_query },
  #       random_score: { "seed": "random_#{rand(1...100000)}" },
  #     }
  #     sort = nil
  #   else
  #     es_query["bool"] = bool_query
  #   end

  #   aggregations =
  #     if options[:totals_agg] == "provider"
  #       provider_aggregations
  #     elsif options[:totals_agg] == "client"
  #       client_aggregations
  #     elsif options[:totals_agg] == "client_export"
  #       client_export_aggregations
  #     elsif options[:totals_agg] == "prefix"
  #       prefix_aggregations
  #     elsif options[:client_type] == "igsnCatalog"
  #       query_aggregations(
  #         disable_facets: options[:disable_facets],
  #         facets: options[:facets],
  #       ).merge(self.igsn_id_catalog_aggregations)
  #     else
  #       query_aggregations(
  #         disable_facets: options[:disable_facets],
  #         facets: options[:facets],
  #       )
  #     end

  #   if options[:sample_group].present?
  #     aggregations[:samples] = {
  #       terms: {
  #         field: options[:sample_group],
  #         size: 10000,
  #       },
  #       aggs: {
  #         "samples_hits": {
  #           top_hits: {
  #             size: options[:sample_size].presence || 1,
  #           },
  #         },
  #       },
  #     }
  #   end

  #   page_size = options.dig(:page, :size) || 25

  #   # Over-fetch from both indices so merged pagination has a better candidate pool.
  #   fetch_size =
  #     if options.dig(:page, :scroll).present?
  #       page_size * 4
  #     elsif options.fetch(:page, {}).key?(:cursor)
  #       page_size * 4
  #     else
  #       ((options.dig(:page, :number) || 1) * page_size * 4)
  #     end

  #   base_search_body = {
  #     size: fetch_size,
  #     sort: sort,
  #     query: es_query,
  #     aggregations: aggregations,
  #     track_total_hits: true,
  #   }.compact

  #   if options.fetch(:page, {}).key?(:cursor)
  #     cursor = [0, ""]
  #     if options.dig(:page, :cursor).is_a?(Array)
  #       timestamp, uid = options.dig(:page, :cursor)
  #       cursor = [timestamp.to_i, uid.to_s]
  #     elsif options.dig(:page, :cursor).is_a?(String)
  #       timestamp, uid = options.dig(:page, :cursor).split(",")
  #       cursor = [timestamp.to_i, uid.to_s]
  #     end

  #     base_search_body[:search_after] = cursor
  #   elsif !options.dig(:page, :scroll).present?
  #     base_search_body[:from] = 0
  #   end

  #   if options.dig(:page, :scroll).present?
  #     begin
  #       response = __elasticsearch__.client.scroll(
  #         body: {
  #           scroll_id: options[:scroll_id],
  #           scroll: options.dig(:page, :scroll),
  #         }
  #       )

  #       hits = response.dig("hits", "hits") || []

  #       merged_hits =
  #         hits.each_with_object({}) do |hit, acc|
  #           doi = hit.dig("_source", "doi")
  #           next if doi.blank?

  #           existing = acc[doi]
  #           if existing.nil? || hit["_index"].to_s.start_with?("enriched_dois")
  #             acc[doi] = hit
  #           end
  #         end.values

  #       return Hashie::Mash.new(
  #         total: merged_hits.length,
  #         results: merged_hits.first(page_size).map do |r|
  #           {
  #             index: r["_index"],
  #             id: r["_id"],
  #             source: r["_source"],
  #             sort: r["sort"],
  #           }
  #         end,
  #         scroll_id: response["_scroll_id"],
  #       )
  #     rescue Elasticsearch::Transport::Transport::Errors::NotFound
  #       return Hashie::Mash.new(
  #         total: 0,
  #         results: [],
  #         scroll_id: nil,
  #       )
  #     end
  #   end

  #   enriched_response = __elasticsearch__.client.search(
  #     index: index_name,
  #     body: base_search_body,
  #   )

  #   doi_response = __elasticsearch__.client.search(
  #     index: Doi.index_name,
  #     body: base_search_body,
  #   )

  #   enriched_hits = enriched_response.dig("hits", "hits") || []
  #   doi_hits = doi_response.dig("hits", "hits") || []

  #   merged_by_doi = {}

  #   enriched_hits.each do |hit|
  #     doi = hit.dig("_source", "doi")
  #     next if doi.blank?
  #     merged_by_doi[doi] = hit
  #   end

  #   doi_hits.each do |hit|
  #     doi = hit.dig("_source", "doi")
  #     next if doi.blank?
  #     merged_by_doi[doi] ||= hit
  #   end

  #   merged_hits = merged_by_doi.values

  #   merged_hits.sort_by! do |hit|
  #     source = hit["_source"] || {}

  #     if sort.nil?
  #       [0]
  #     elsif sort == [{ created: "asc" }, { uid: "asc" }]
  #       [
  #         source["created"].to_s,
  #         source["uid"].to_s,
  #       ]
  #     else
  #       first_sort = Array.wrap(sort).first || {}
  #       field, spec = first_sort.first
  #       order = spec.is_a?(Hash) ? spec[:order] || spec["order"] : spec

  #       value =
  #         case field.to_s
  #         when "doi"
  #           source["doi"].to_s
  #         when "updated"
  #           source["updated"].to_s
  #         when "created"
  #           source["created"].to_s
  #         when "published"
  #           source["published"].to_s
  #         when "view_count"
  #           source["view_count"].to_i
  #         when "download_count"
  #           source["download_count"].to_i
  #         when "citation_count"
  #           source["citation_count"].to_i
  #         when "primary_title.title.raw"
  #           Array.wrap(source["primary_title"]).first&.dig("title").to_s
  #         when "_score"
  #           -(hit["_score"] || 0.0)
  #         else
  #           source[field.to_s].to_s
  #         end

  #       if order.to_s == "desc"
  #         if value.is_a?(Numeric)
  #           [-value, source["doi"].to_s]
  #         else
  #           [value.to_s, source["doi"].to_s]
  #         end
  #       else
  #         [value, source["doi"].to_s]
  #       end
  #     end
  #   end

  #   unless sort.nil?
  #     first_sort = Array.wrap(sort).first || {}
  #     field, spec = first_sort.first
  #     order = spec.is_a?(Hash) ? spec[:order] || spec["order"] : spec

  #     if %w[updated created published doi primary_title.title.raw].include?(field.to_s) && order.to_s == "desc"
  #       merged_hits.reverse!
  #     end
  #   end

  #   paged_hits =
  #     if options.fetch(:page, {}).key?(:cursor)
  #       merged_hits.first(page_size)
  #     else
  #       page_number = options.dig(:page, :number) || 1
  #       offset = (page_number - 1) * page_size
  #       merged_hits.slice(offset, page_size) || []
  #     end

  #   merged_total = merged_hits.length

  #   merge_buckets = lambda do |enriched_buckets, doi_buckets|
  #     merged = {}

  #     Array.wrap(enriched_buckets).each do |bucket|
  #       key = bucket["key"] || bucket[:key]
  #       merged[key] = bucket
  #     end

  #     Array.wrap(doi_buckets).each do |bucket|
  #       key = bucket["key"] || bucket[:key]
  #       merged[key] ||= bucket
  #     end

  #     merged.values
  #   end

  #   merge_aggs = lambda do |enriched_aggs, doi_aggs|
  #     enriched_aggs ||= {}
  #     doi_aggs ||= {}

  #     keys = enriched_aggs.keys | doi_aggs.keys

  #     keys.each_with_object({}) do |key, acc|
  #       enriched_value = enriched_aggs[key]
  #       doi_value = doi_aggs[key]

  #       if enriched_value.is_a?(Hash) && doi_value.is_a?(Hash)
  #         if enriched_value.key?("buckets") || doi_value.key?("buckets")
  #           acc[key] = (enriched_value || {}).merge(
  #             "buckets" => merge_buckets.call(
  #               enriched_value&.dig("buckets"),
  #               doi_value&.dig("buckets")
  #             )
  #           )
  #         elsif enriched_value.key?("value") || doi_value.key?("value")
  #           acc[key] = enriched_value.presence || doi_value
  #         else
  #           acc[key] = merge_aggs.call(enriched_value, doi_value)
  #         end
  #       else
  #         acc[key] = enriched_value.presence || doi_value
  #       end
  #     end
  #   end

  #   merged_aggs = merge_aggs.call(
  #     enriched_response["aggregations"] || {},
  #     doi_response["aggregations"] || {},
  #   )

  #   Hashie::Mash.new(
  #     total: merged_total,
  #     results: paged_hits.map do |r|
  #       {
  #         index: r["_index"],
  #         id: r["_id"],
  #         source: r["_source"],
  #         sort: r["sort"],
  #       }
  #     end,
  #     aggregations: Hashie::Mash.new(merged_aggs || {}),
  #   )
  # end
end
