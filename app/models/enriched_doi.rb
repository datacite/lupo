# frozen_string_literal: true

class EnrichedDoi < Doi
  include Elasticsearch::Model

  if Rails.env.test?
    index_name("enriched_dois-test#{ENV['TEST_ENV_NUMBER']}")
  elsif ENV["ES_PREFIX"].present?
    index_name("enriched_dois-#{ENV['ES_PREFIX']}")
  else
    index_name("enriched_dois")
  end

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: "keyword", filter: %w(lowercase ascii_folding) },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w(lowercase) },
      },
      filter: {
        ascii_folding: { type: "asciifolding", preserve_original: true },
      },
    },
  } do
    mapping dynamic: "false" do
      indexes :id,                             type: :keyword, normalizer: "keyword_lowercase"
      indexes :uid,                            type: :keyword, normalizer: "keyword_lowercase"
      indexes :doi,                            type: :keyword, normalizer: "keyword_lowercase"
      indexes :identifier,                     type: :keyword
      indexes :url,                            type: :text, fields: { keyword: { type: "keyword" } }
      indexes :creators,                       type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :text },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
      }
      indexes :contributors, type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :text },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        contributorType: { type: :keyword },
      }
      indexes :creators_and_contributors, type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        contributorType: { type: :keyword },
      }
      indexes :creator_names,                  type: :text
      indexes :titles,                         type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" } } },
        titleType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :descriptions, type: :object, properties: {
        description: { type: :text },
        descriptionType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :publisher,                      type: :text,
        fields: { keyword: { type: "keyword" } }
      indexes :publication_year,               type: :date, format: "yyyy", ignore_malformed: true
      indexes :client_id,                      type: :keyword
      indexes :provider_id,                    type: :keyword
      indexes :consortium_id,                  type: :keyword
      indexes :resource_type_id,               type: :keyword
      indexes :person_id,                      type: :keyword
      indexes :affiliation_id,                 type: :keyword
      indexes :fair_affiliation_id,            type: :keyword
      indexes :organization_id,                type: :keyword
      indexes :fair_organization_id,           type: :keyword
      indexes :related_dmp_organization_id,    type: :keyword
      indexes :funder_rors,                    type: :keyword
      indexes :funder_parent_rors,           type: :keyword
      indexes :affiliation_countries,          type: :keyword
      indexes :client_id_and_name,             type: :keyword
      indexes :provider_id_and_name,           type: :keyword
      indexes :resource_type_id_and_name,      type: :keyword
      indexes :affiliation_id_and_name,        type: :keyword
      indexes :fair_affiliation_id_and_name,   type: :keyword
      indexes :media_ids,                      type: :keyword
      indexes :media,                          type: :object, properties: {
        type: { type: :keyword },
        id: { type: :keyword },
        uid: { type: :keyword },
        url: { type: :text },
        media_type: { type: :keyword },
        version: { type: :keyword },
        created: { type: :date, ignore_malformed: true },
        updated: { type: :date, ignore_malformed: true },
      }
      indexes :identifiers, type: :object, properties: {
        identifierType: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
      }
      indexes :related_identifiers, type: :object, properties: {
        relatedIdentifierType: { type: :keyword },
        relatedIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        relationType: { type: :keyword },
        relatedMetadataScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        schemeType: { type: :keyword },
        resourceTypeGeneral: { type: :keyword },
        relationTypeInformation: { type: :text },
      }
      indexes :related_items, type: :object, properties: {
        relatedItemType: { type: :keyword },
        relationType: { type: :keyword },
        relationTypeInformation: { type: :text },
        relatedItemIdentifier: { type: :object, properties: {
          relatedItemIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
          relatedItemIdentifierType: { type: :keyword },
          relatedMetadataScheme: { type: :keyword },
          schemeURI: { type: :keyword },
          schemeType: { type: :keyword },
        } },
        creators: { type: :object, properties: {
          nameType: { type: :text },
          name: { type: :text },
          givenName: { type: :text },
          familyName: { type: :text },
        } },
        titles: { type: :object, properties: {
          title: { type: :text, fields: { keyword: { type: "keyword" } } },
          titleType: { type: :keyword },
        } },
        volume: { type: :keyword },
        issue: { type: :keyword },
        number: { type: :keyword },
        numberType: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword },
        publisher: { type: :text },
        publicationYear: { type: :keyword },
        edition: { type: :keyword },
        contributors: { type: :object, properties: {
          contributorType: { type: :text },
          name: { type: :text },
          nameType: { type: :text },
          givenName: { type: :text },
          familyName: { type: :text },
        } },
      }
      indexes :types, type: :object, properties: {
        resourceTypeGeneral: { type: :keyword },
        resourceType: { type: :keyword, normalizer: "keyword_lowercase" },
        schemaOrg: { type: :keyword },
        bibtex: { type: :keyword },
        citeproc: { type: :keyword },
        ris: { type: :keyword },
      }
      indexes :funding_references, type: :object, properties: {
        funderName: { type: :text },
        funderIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        funderIdentifierType: { type: :keyword },
        schemeUri: { type: :keyword },
        awardNumber: { type: :keyword },
        awardUri: { type: :keyword },
        awardTitle: { type: :keyword },
      }
      indexes :dates, type: :object, properties: {
        date: { type: :text },
        dateType: { type: :keyword },
        dateInformation: { type: :keyword },
      }
      indexes :geo_locations, type: :object, properties: {
        geoLocationPlace: { type: :keyword },
        geoLocationPoint: { type: :object, properties: {
          pointLatitude: { type: :float },
          pointLongitude: { type: :float },
        } },
        geoLocationBox: { type: :object, properties: {
          westBoundLongitude: { type: :float  },
          eastBoundLongitude: { type: :float  },
          southBoundLatitude: { type: :float  },
          northBoundLatitude: { type: :float  },
        } },
        geoLocationPolygon: { type: :object, properties: {
          polygonPoint: { type: :object, properties: {
            pointLatitude: { type: :float },
            pointLongitude: { type: :float },
          } },
          inPolygonPoint: { type: :object, properties: {
            pointLatitude: { type: :float },
            pointLongitude: { type: :float },
          } },
        } },
      }
      indexes :rights_list, type: :object, properties: {
        rights: { type: :keyword },
        rightsUri: { type: :keyword },
        rightsIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        rightsIdentifierScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :subjects, type: :object, properties: {
        subjectScheme: { type: :keyword },
        subject: {
          type: :text,
         fields: {
          keyword: {
            type: :keyword
          }
         }
        },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword },
        classificationCode: { type: :keyword },
      }
      indexes :container, type: :object, properties: {
        type: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
        identifierType: { type: :keyword },
        title: { type: :keyword },
        volume: { type: :keyword },
        issue: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword },
      }

      indexes :xml,                            type: :text, index: "false"
      indexes :content_url,                    type: :keyword
      indexes :version_info,                   type: :keyword
      indexes :formats,                        type: :keyword
      indexes :sizes,                          type: :keyword
      indexes :language,                       type: :keyword
      indexes :is_active,                      type: :keyword
      indexes :aasm_state,                     type: :keyword
      indexes :schema_version,                 type: :keyword
      indexes :metadata_version,               type: :keyword
      indexes :agency,                         type: :keyword
      indexes :source,                         type: :keyword
      indexes :prefix,                         type: :keyword
      indexes :suffix,                         type: :keyword
      indexes :reason,                         type: :text
      indexes :landing_page, type: :object, properties: {
        checked: { type: :date, ignore_malformed: true },
        url: { type: :text, fields: { keyword: { type: "keyword" } } },
        status: { type: :integer },
        contentType: { type: :keyword },
        error: { type: :keyword },
        redirectCount: { type: :integer },
        redirectUrls: { type: :keyword },
        downloadLatency: { type: :scaled_float, scaling_factor: 100 },
        hasSchemaOrg: { type: :boolean },
        schemaOrgId: { type: :keyword },
        dcIdentifier: { type: :keyword },
        citationDoi: { type: :keyword },
        bodyHasPid: { type: :boolean },
      }
      indexes :cache_key,                      type: :keyword
      indexes :registered,                     type: :date, ignore_malformed: true
      indexes :published,                      type: :date, ignore_malformed: true
      indexes :created,                        type: :date, ignore_malformed: true
      indexes :updated,                        type: :date, ignore_malformed: true

      # include parent objects
      indexes :client,                         type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        symbol: { type: :keyword },
        provider_id: { type: :keyword },
        re3data_id: { type: :keyword },
        opendoar_id: { type: :keyword },
        salesforce_id: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        alternate_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        description: { type: :text },
        language: { type: :keyword },
        client_type: { type: :keyword },
        repository_type: { type: :keyword },
        certificate: { type: :keyword },
        system_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        version: { type: :integer },
        is_active: { type: :keyword },
        domains: { type: :text },
        year: { type: :integer },
        url: { type: :text, fields: { keyword: { type: "keyword" } } },
        software: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        cache_key: { type: :keyword },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" },
        subjects: { type: :object, properties: {
          subjectScheme: { type: :keyword },
          subject: { type: :keyword },
          schemeUri: { type: :keyword },
          valueUri: { type: :keyword },
          lang: { type: :keyword },
          classificationCode: { type: :keyword },
        } }
      }
      indexes :provider, type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        symbol: { type: :keyword },
        client_ids: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        display_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        system_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        group_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        version: { type: :integer },
        is_active: { type: :keyword },
        year: { type: :integer },
        description: { type: :text },
        website: { type: :text, fields: { keyword: { type: "keyword" } } },
        logo_url: { type: :text },
        region: { type: :keyword },
        focus_area: { type: :keyword },
        organization_type: { type: :keyword },
        member_type: { type: :keyword },
        consortium_id: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        consortium_organization_ids: { type: :keyword },
        country_code: { type: :keyword },
        role_name: { type: :keyword },
        cache_key: { type: :keyword },
        joined: { type: :date },
        twitter_handle: { type: :keyword },
        ror_id: { type: :keyword },
        salesforce_id: { type: :keyword },
        billing_information: { type: :object, properties: {
          postCode: { type: :keyword },
          state: { type: :text },
          organization: { type: :text },
          department: { type: :text },
          city: { type: :text },
          country: { type: :text },
          address: { type: :text },
        } },
        technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        secondary_technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        billing_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        secondary_billing_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        service_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        secondary_service_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        voting_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" },
        consortium: { type: :object },
        consortium_organizations: { type: :object },
      }
      indexes :resource_type, type: :object
      indexes :view_count, type: :integer
      indexes :download_count, type: :integer
      indexes :reference_count, type: :integer
      indexes :citation_count, type: :integer
      indexes :part_count, type: :integer
      indexes :part_of_count, type: :integer
      indexes :version_count, type: :integer
      indexes :version_of_count, type: :integer
      indexes :views_over_time, type: :object
      indexes :downloads_over_time, type: :object
      indexes :citations_over_time, type: :object
      indexes :part_ids, type: :keyword
      indexes :part_of_ids, type: :keyword
      indexes :version_ids, type: :keyword
      indexes :version_of_ids, type: :keyword
      indexes :reference_ids, type: :keyword
      indexes :citation_ids, type: :keyword
      indexes :primary_title, type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        titleType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :fields_of_science, type: :keyword
      indexes :fields_of_science_combined, type: :keyword
      indexes :fields_of_science_repository, type: :keyword
      indexes :related_doi, type: :object, properties: {
        client_id: { type: :keyword },
        doi: { type: :keyword },
        organization_id: { type: :keyword },
        person_id: { type: :keyword },
        resource_type_id: { type: :keyword },
        resource_type_id_and_name: { type: :keyword },
      }
      indexes :publisher_obj, type: :object, properties: {
        name: { type: :text, fields: { keyword: { type: "keyword" } } },
        publisherIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        publisherIdentifierScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        lang: { type: :keyword },
      }
    end
  end

  def extra_indexed_fields
    {
      "enrichments" => enrichment_uuids,
    }
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

  def self.enriched_query(query, options = {})
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

    # if options[:show_enrichments]
    #   must_not << {
    #     bool: {
    #       filter: [
    #         { prefix: { _index: "dois" } },
    #         { term: { has_enrichments: true } }
    #       ]
    #     }
    #   }
    # end

    # ES query can be op tionally defined in different ways
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
    if options.dig(:page, :scroll).present?
      response = __elasticsearch__.client.search(
        index: search_indices,
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
        results: response.dig("hits", "hits").map { |r| r["_source"] },
        scroll_id: response["_scroll_id"],
      )
    elsif options.fetch(:page, {}).key?(:cursor)
      __elasticsearch__.search({
        index: search_indices,
        size: options.dig(:page, :size),
        search_after: search_after,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true,
      }.compact)
    else
      __elasticsearch__.search({
        index: search_indices,
        size: options.dig(:page, :size),
        from: from,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true,
      }.compact)
    end
  end
end
