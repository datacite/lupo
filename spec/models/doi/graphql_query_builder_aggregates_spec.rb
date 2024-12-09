# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::GraphqlQuery::Builder do
  let(:query) { "" }
  let(:options) { {} }

  describe "aggregations" do
    it "by default all aggregations are enabled" do
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq(
        {
          affiliations: { terms: { field: "affiliation_id_and_name", min_doc_count: 1, missing: "__missing__", size: 10 } },
          authors: {
            aggs: { authors: {
              top_hits: { _source: {
                includes: ["creators.name", "creators.nameIdentifiers.nameIdentifier"],
              }, size: 1 },
            } },
            terms: { field: "creators.nameIdentifiers.nameIdentifier", include: "https?://orcid.org/.*", min_doc_count: 1, size: 10 },
          },
          citation_count: {
            sum: { field: "citation_count" },
          },
          client_types: {
            terms: { field: "client.client_type", min_doc_count: 1, size: 10 },
          },
          clients: {
            terms: { field: "client_id_and_name", min_doc_count: 1, size: 10 },
          },
          content_url_count: {
            value_count: { field: "content_url" },
          },
          creators_and_contributors: {
            aggs: {
              creators_and_contributors: {
                top_hits: { _source: {
                  includes: ["creators_and_contributors.name", "creators_and_contributors.nameIdentifiers.nameIdentifier"],
                }, size: 1 },
              },
              work_types: { terms: { field: "resource_type_id_and_name", min_doc_count: 1 } },
            },
            terms: {
              field: "creators_and_contributors.nameIdentifiers.nameIdentifier",
              include: "https?://orcid.org/.*",
              min_doc_count: 1,
              size: 10,
            },
          },
          download_count: {
            sum: { field: "download_count" },
          },
          fields_of_science: {
            aggs: {
              subject: {
                terms: {
                  field: "subjects.subject",
                  include: "FOS:.*",
                  min_doc_count: 1,
                  size: 10,
                },
              },
            },
            filter: {
              term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" },
            },
          },
          fields_of_science_combined: {
            terms: {
              field: "fields_of_science_combined",
              min_doc_count: 1,
              size: 10,
            },
          },
          fields_of_science_repository: {
            terms: {
              field: "fields_of_science_repository",
              min_doc_count: 1,
              size: 10,
            },
          },
          funders: {
            aggs: { funders: { top_hits: { _source: { includes: ["funding_references.funderName", "funding_references.funderIdentifier"] }, size: 1 } } },
            terms: {
              field: "funding_references.funderIdentifier",
              min_doc_count: 1,
              size: 10,
            },
          },
          languages: {
            terms: {
              field: "language",
              min_doc_count: 1,
              size: 10,
            },
          },
          licenses: {
            terms: {
              field: "rights_list.rightsIdentifier",
              min_doc_count: 1,
              missing: "__missing__",
              size: 10,
            },
          },
          open_licenses: {
            aggs: {
              resource_types: {
                terms: {
                  field: "resource_type_id_and_name",
                  min_doc_count: 1,
                  size: 10,
                },
              },
            },
            filter: {
              terms: { "rights_list.rightsIdentifier": [
                "cc-by-1.0",
                "cc-by-2.0",
                "cc-by-2.5",
                "cc-by-3.0",
                "cc-by-3.0-at",
                "cc-by-3.0-us",
                "cc-by-4.0",
                "cc-pddc",
                "cc0-1.0",
                "cc-pdm-1.0",
              ] },
            },
          },
          pid_entities: {
            aggs: {
              subject: {
                terms: {
                  field: "subjects.subject",
                  include: [
                    "Dataset",
                    "Publication",
                    "Software",
                    "Organization",
                    "Funder",
                    "Person",
                    "Grant",
                    "Sample",
                    "Instrument",
                    "Repository",
                    "Project",
                  ],
                  min_doc_count: 1,
                  size: 10,
                },
              },
            },
            filter: { term: { "subjects.subjectScheme": "PidEntity" } },
          },
          published: {
            date_histogram: {
              field: "publication_year",
              format: "year",
              interval: "year",
              min_doc_count: 1,
              order: { _key: "desc" },
            },
          },
          registration_agencies: {
            terms: { field: "agency", min_doc_count: 1, size: 10 },
          },
          resource_types: { terms: {
            field: "resource_type_id_and_name",
            min_doc_count: 1,
            missing: "__missing__",
            size: 10,
          } },
          view_count: {
            sum: { field: "view_count" },
          },
        }
      )
    end

    it "has keys for all aggregates" do
      expected_keys = %i[
        affiliations
        authors
        citation_count
        client_types
        clients
        content_url_count
        creators_and_contributors
        download_count
        fields_of_science
        fields_of_science_combined
        fields_of_science_repository
        funders
        languages
        licenses
        open_licenses
        pid_entities
        published
        registration_agencies
        resource_types
        view_count
      ]

      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end
  end

  describe "include aggregations" do
    it "includes all aggregations by default" do
      expected_keys = described_class.all_aggregation_keys
      options = {}
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "includes all aggregations when :all symbol provided" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: :all }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "includes all aggregations when 'all' string provided" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: 'all' }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "returns empty hash when :none provided" do
      options = { include_aggregations: :none }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "returns empty hash when 'none' string provided" do
      options = { include_aggregations: 'none' }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "includes only specified aggregations when array of symbols provided" do
      options = { include_aggregations: [:clients, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "ignores invalid aggregation keys" do
      options = { include_aggregations: [:clients, :invalid_key, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "includes all aggregations when :all is included in array" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: [:clients, :all, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end
  end
end
