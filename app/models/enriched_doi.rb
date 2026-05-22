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
end
