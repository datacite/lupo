# frozen_string_literal: true

module Doi::GraphqlQuery
  class Builder
    include Modelable

    DEFAULT_CURSOR = [0, ""]
    DEFAULT_PAGE_SIZE = 0
    DEFAULT_FACET_COUNT = 10
    DEFAULT_SORT = [{ created: "asc", uid: "asc" }]

    def initialize(query, options)
      @query = query
      @options = options
    end

    def build_full_search_query
      {
        size: size,
        search_after: search_after,
        sort: sort,
        query: inner_query,
        aggregations: aggregations,
        track_total_hits: true,
      }.compact
    end

    def size
      (@options.dig(:page, :size) || DEFAULT_PAGE_SIZE).to_i
    end

    def sort
      DEFAULT_SORT
    end

    def query_fields
      [
        "uid^50",
        "related_identifiers.relatedIdentifier^3",
        "titles.title^3",
        "creator_names^3",
        "creators.id^3",
        "publisher^3",
        "descriptions.description^3",
        "subjects.subject^3"
      ]
    end

    def cursor
      tmp_cursor = @options.dig(:page, :cursor)
      if tmp_cursor.nil?
        return DEFAULT_CURSOR
      end

      if tmp_cursor.is_a?(Array)
        timestamp, uid = tmp_cursor
      elsif tmp_cursor.is_a?(String)
        timestamp, uid = tmp_cursor.split(",")
      end
      [timestamp.to_i, uid.to_s]
    end

    def search_after
      cursor
    end

    QUERY_SUBSTITUTIONS = {
      "publicationYear" => "publication_year",
      "relatedIdentifiers" => "related_identifiers",
      "relatedItems" => "related_items",
      "rightsList" => "rights_list",
      "fundingReferences" => "funding_references",
      "geoLocations" => "geo_locations",
      "landingPage" => "landing_page",
      "contentUrl" => "content_url",
      "citationCount" => "citation_count",
      "viewCount" => "view_count",
      "downloadCount" => "download_count"
    }


    def clean_query
      # make sure field name uses underscore
      # escape forward slash, but not other Elasticsearch special characters
      if @query.present?
        @query.gsub(/publicationYear/, "publication_year")\
          .gsub(/relatedIdentifiers/, "related_identifiers")\
          .gsub(/relatedItems/, "related_items")\
          .gsub(/rightsList/, "rights_list")\
          .gsub(/fundingReferences/, "funding_references")\
          .gsub(/geoLocations/, "geo_locations")\
          .gsub(/version:/, "version_info:")\
          .gsub(/landingPage/, "landing_page")\
          .gsub(/contentUrl/, "content_url")\
          .gsub(/citationCount/, "citation_count")\
          .gsub(/viewCount/, "view_count")\
          .gsub(/downloadCount/, "download_count")\
          .gsub(/(publisher\.)(name|publisherIdentifier|publisherIdentifierScheme|schemeUri|lang)/, 'publisher_obj.\2')\
          .gsub("/", "\\/")
      else
        ""
      end
    end

    def must
      if !@query.present?
        [{ match_all: {} }]
      else
        [{
          query_string: {
            query: clean_query,
            fields: query_fields,
            default_operator: "AND",
            phrase_slop: 1
          }
        }]
      end
    end

    def filters
      Doi::Search::FilterBuilder.new(@options).build
    end

    def get_should_clause
      options = @options
      should_query = []
      minimum_should_match = 0
      if options[:provider_id].present?
        options[:provider_id].split(",").each { |id|
          should_query << { term: { "provider_id": { value: id, case_insensitive: true } } }
        }
        minimum_should_match = 1
      end
      if options[:client_id].present?
        options[:client_id].split(",").each { |id|
          should_query << { term: { "client_id": { value: id, case_insensitive: true } } }
        }
        minimum_should_match = 1
      end
      # match either one of has_affiliation, has_organization, has_funder or has_member
      if options[:has_organization].present?
        should_query << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
        should_query << { term: { "contributors.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
        minimum_should_match = 1
      end
      if options[:has_affiliation].present?
        should_query << { term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" } }
        should_query << { term: { "contributors.affiliation.affiliationIdentifierScheme" => "ROR" } }
        minimum_should_match = 1
      end
      if options[:has_funder].present?
        should_query << { term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" } }
        minimum_should_match = 1
      end
      if options[:has_member].present?
        should_query << { exists: { field: "provider.ror_id" } }
        minimum_should_match = 1
      end

      # match either ROR ID or Crossref Funder ID if either organization_id, affiliation_id,
      # funder_id or member_id is a query parameter
      if options[:organization_id].present?
        # TODO: remove after organization_id has been indexed
        should_query << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
        # TODO: remove after organization_id has been indexed
        should_query << { term: { "contributors.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
        should_query << { term: { "organization_id" => ror_from_url(options[:organization_id]) } }
        minimum_should_match = 1
      end

      if options[:fair_organization_id].present?
        _ror_id = ror_from_url(options[:fair_organization_id])
        should_query << { term: { "organization_id" => _ror_id } }
        should_query << { term: { "affiliation_id" => _ror_id } }
        should_query << { term: { "related_dmp_organization_id" => _ror_id } }
        minimum_should_match = 1
      end

      if options[:affiliation_id].present?
        should_query << { term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) } }
        minimum_should_match = 1
      end
      if options[:funder_id].present?
        should_query << { terms: { "funding_references.funderIdentifier" => options[:funder_id].split(",").map { |f| "https://doi.org/#{doi_from_url(f)}" } } }
        minimum_should_match = 1
      end
      if options[:member_id].present?
        should_query << { term: { "provider.ror_id" => "https://#{ror_from_url(options[:member_id])}" } }
        minimum_should_match = 1
      end

      OpenStruct.new(
        should_query: should_query,
        minimum_should_match: minimum_should_match
      )
    end

    def inner_query
      should = get_should_clause
      {
        bool: {
          must: must,
          filter: filters,
          should: should.should_query,
          minimum_should_match: should.minimum_should_match,
        },
      }.compact
    end

    def aggregations
      facet_count = (@options[:facet_count] || DEFAULT_FACET_COUNT).to_i
      if facet_count.positive?
        {
          resource_types: { terms: { field: "resource_type_id_and_name", size: facet_count, min_doc_count: 1, missing: "__missing__" } },
          clients: { terms: { field: "client_id_and_name", size: facet_count, min_doc_count: 1 } },
          open_licenses: {
            filter: { terms: {
              "rights_list.rightsIdentifier": [
                "cc-by-1.0",
                "cc-by-2.0",
                "cc-by-2.5",
                "cc-by-3.0",
                "cc-by-3.0-at",
                "cc-by-3.0-us",
                "cc-by-4.0",
                "cc-pddc",
                "cc0-1.0",
                "cc-pdm-1.0"
              ]
            } },
            aggs: {
              resource_types: {
                terms: { field: "resource_type_id_and_name", size: facet_count, min_doc_count: 1 }
              }
            }
          },
          published: {
            date_histogram: {
              field: "publication_year",
              interval: "year",
              format: "year",
              order: {
                _key: "desc",
              },
              min_doc_count: 1,
            },
          },
          registration_agencies: { terms: { field: "agency", size: facet_count, min_doc_count: 1 } },
          affiliations: { terms: { field: "affiliation_id_and_name", size: facet_count, min_doc_count: 1, missing: "__missing__" } },
          authors: {
            terms: { field: "creators.nameIdentifiers.nameIdentifier", size: facet_count, min_doc_count: 1, include: "https?://orcid.org/.*" },
            aggs: {
              authors: {
                top_hits: {
                  _source: {
                    includes: [ "creators.name", "creators.nameIdentifiers.nameIdentifier"]
                  },
                  size: 1
                }
              }
            }
          },
          creators_and_contributors: {
            terms: {
              field: "creators_and_contributors.nameIdentifiers.nameIdentifier",
              size: facet_count,
              min_doc_count: 1,
              include: "https?://orcid.org/.*"
            },
            aggs: {
              creators_and_contributors: {
                top_hits: {
                  _source: {
                    includes: [
                      "creators_and_contributors.name",
                      "creators_and_contributors.nameIdentifiers.nameIdentifier"
                    ]
                  },
                  size: 1
                }
              },
              "work_types": {
                "terms": {
                  "field": "resource_type_id_and_name",
                  "min_doc_count": 1
                }
              }
            }
          },
          funders: {
            terms: {
              field: "funding_references.funderIdentifier",
              size: facet_count,
              min_doc_count: 1
            },
            aggs: {
              funders: {
                top_hits: {
                  _source: {
                    includes: [
                      "funding_references.funderName",
                      "funding_references.funderIdentifier"
                    ]
                  },
                  size: 1
                }
              }
            }
          },
          pid_entities: {
            filter: { term: { "subjects.subjectScheme": "PidEntity" } },
            aggs: {
              subject: { terms: {
                field: "subjects.subject",
                size: facet_count,
                min_doc_count: 1,
                include: %w(
                  Dataset
                  Publication
                  Software
                  Organization
                  Funder
                  Person
                  Grant
                  Sample
                  Instrument
                  Repository
                  Project
                )
              } },
            },
          },
          fields_of_science: {
            filter: { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } },
            aggs: {
              subject: { terms: { field: "subjects.subject", size: facet_count, min_doc_count: 1,
                                  include: "FOS:.*" } },
            },
          },
          fields_of_science_combined: {
            terms: { field: "fields_of_science_combined", size: facet_count, min_doc_count: 1 }
          },
          fields_of_science_repository: {
            terms: { field: "fields_of_science_repository", size: facet_count, min_doc_count: 1 }
          },
          licenses: { terms: { field: "rights_list.rightsIdentifier", size: facet_count, min_doc_count: 1, missing: "__missing__" } },
          languages: { terms: { field: "language", size: facet_count, min_doc_count: 1 } },
          view_count: { sum: { field: "view_count" } },
          download_count: { sum: { field: "download_count" } },
          citation_count: { sum: { field: "citation_count" } },
          content_url_count: { value_count: { field: "content_url" } },
          client_types: {
            terms: {
              field: "client.client_type",
              size: facet_count,
              min_doc_count: 1
            }
          }
        }
      end
    end
  end
end
