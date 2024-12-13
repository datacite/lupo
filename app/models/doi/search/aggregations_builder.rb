# frozen_string_literal: true

module Doi::Search
  class AggregationsBuilder
    DEFAULT_FACET_COUNT = 10

    def initialize(options)
      @options = options
      @facet_count = (@options[:facet_count] || DEFAULT_FACET_COUNT).to_i
      @selected_aggs = selected_aggs
    end

    def build
      return {} if @facet_count == 0
      aggs = @selected_aggs
      facet_sizes.each do |key, size|
        aggs[key][:terms][:size] = size.to_i if aggs[key]&.dig(:terms)
      end
      aggs
    end

    def facet_sizes
      custom_sizes = (@options[:facet_sizes] || {}).select do |key, value|
        @selected_aggs.key?(key.to_sym) && value.to_i.positive?
      end.transform_keys(&:to_sym)

      if @facet_count != DEFAULT_FACET_COUNT && @facet_count.positive?
        # Create a hash with facet_count for all selected aggregations that have terms
        default_sizes = @selected_aggs.each_with_object({}) do |(key, agg), hash|
          hash[key] = @facet_count if agg&.dig(:terms)
        end

        # Let custom sizes override the defaults
        default_sizes.merge(custom_sizes)
      else
        custom_sizes
      end
    end

    def requested_aggs
      included_aggs = @options[:include_aggregations] || :all
      if included_aggs.is_a?(String)
        included_aggs = included_aggs.split(",").map(&:strip)
      end
      return {} if included_aggs == :none || included_aggs == "none"

      Array.wrap(included_aggs).map(&:to_sym)
    end

    def selected_aggs
      tmp_aggs = if requested_aggs.include?(:all)
        AGGREGATION_DEFINITIONS
      else
        AGGREGATION_DEFINITIONS.slice(*requested_aggs)
      end
      Marshal.load(Marshal.dump(tmp_aggs))
    end

    def self.all_aggregation_keys
      AGGREGATION_DEFINITIONS.keys
    end

    def self.all_aggregations
      AGGREGATION_DEFINITIONS
    end

    private
      AGGREGATION_DEFINITIONS = {
        resource_types: {
          terms: {
            field: "resource_type_id_and_name",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
            missing: "__missing__",
          },
        },
        clients: { terms: {
          field: "client_id_and_name",
          size: DEFAULT_FACET_COUNT,
          min_doc_count: 1,
        } },
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
              terms: {
                field: "resource_type_id_and_name",
                size: DEFAULT_FACET_COUNT,
                min_doc_count: 1,
              }
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
        registration_agencies: {
          terms: {
            field: "agency",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
          },
        },
        affiliations: {
          terms: {
            field: "affiliation_id_and_name",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
            missing: "__missing__",
          },
        },
        authors: {
          terms: {
            field: "creators.nameIdentifiers.nameIdentifier",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
            include: "https?://orcid.org/.*",
          },
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
            size: DEFAULT_FACET_COUNT,
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
            size: DEFAULT_FACET_COUNT,
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
              size: DEFAULT_FACET_COUNT,
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
          filter: {
            term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" },
          },
          aggs: {
            subject: { terms: {
              field: "subjects.subject",
              size: DEFAULT_FACET_COUNT,
              min_doc_count: 1,
              include: "FOS:.*",
            } },
          },
        },
        fields_of_science_combined: {
          terms: {
            field: "fields_of_science_combined",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
          }
        },
        fields_of_science_repository: {
          terms: {
            field: "fields_of_science_repository",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
          }
        },
        licenses: {
          terms: {
            field: "rights_list.rightsIdentifier",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
            missing: "__missing__",
          },
        },
        languages: {
          terms: {
            field: "language",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1,
          },
        },
        view_count: { sum: { field: "view_count" } },
        download_count: { sum: { field: "download_count" } },
        citation_count: { sum: { field: "citation_count" } },
        content_url_count: { value_count: { field: "content_url" } },
        client_types: {
          terms: {
            field: "client.client_type",
            size: DEFAULT_FACET_COUNT,
            min_doc_count: 1
          }
        }
      }.freeze
  end
end
