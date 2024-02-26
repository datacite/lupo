# frozen_string_literal: true

require "rails_helper"

describe DataManagementPlanType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query data_management_plans", elasticsearch: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        language: "de",
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        dataManagementPlans {
          totalCount
          registrationAgencies {
            id
            title
            count
          }
          licenses {
            id
            title
            count
          }
          languages {
            id
            title
            count
          }
          nodes {
            id
            registrationAgency {
              id
              name
            }
          }
        }
      }"
    end

    it "returns all data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dataManagementPlans", "totalCount")).to eq(2)
      expect(response.dig("data", "dataManagementPlans", "languages")).to eq(
        [{ "count" => 2, "id" => "de", "title" => "German" }],
      )
      expect(response.dig("data", "dataManagementPlans", "licenses")).to eq(
        [{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }],
      )
      expect(response.dig("data", "dataManagementPlans", "nodes").length).to eq(
        2,
      )
      expect(
        response.dig(
          "data",
          "dataManagementPlans",
          "nodes",
          0,
          "registrationAgency",
        ),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query data_management_plans from an organization",
           elasticsearch: true, vcr: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        language: "de",
        aasm_state: "findable",
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100000780",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "European Commission",
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        organization(id: \"https://ror.org/00k4n6c32\") {
          name
          dataManagementPlans {
            totalCount
            registrationAgencies {
              id
              title
              count
            }
            licenses {
              id
              title
              count
            }
            languages {
              id
              title
              count
            }
            nodes {
              id
              types {
                resourceTypeGeneral
                resourceType
                schemaOrg
              }
              registrationAgency {
                id
                name
              }
            }
          }
        }
      }"
    end

    it "returns all data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "name")).to eq("European Commission")
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "totalCount",
        ),
      ).to eq(2)
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "languages",
        ),
      ).to eq([{ "count" => 2, "id" => "de", "title" => "German" }])
      expect(
        response.dig("data", "organization", "dataManagementPlans", "licenses"),
      ).to eq([{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }])
      expect(
        response.dig("data", "organization", "dataManagementPlans", "nodes").
          length,
      ).to eq(2)
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "nodes",
          0,
          "registrationAgency",
        ),
      ).to eq("id" => "datacite", "name" => "DataCite")
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "nodes",
          0,
          "types",
        ),
      ).to eq(
        "resourceType" => "Data Management Plan",
        "resourceTypeGeneral" => "Text",
        "schemaOrg" => "ScholarlyArticle",
      )
    end
  end

  describe "query data_management_plans from an organization as contributor name identifier",
           elasticsearch: true, vcr: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        language: "de",
        aasm_state: "findable",
        contributors: [
          {
            "name" => "European Commission",
            "contributorType" => "Sponsor",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/00k4n6c32",
                "nameIdentifierScheme" => "ROR",
                "schemeUri" => "https://ror.org",
              },
            ],
            "nameType" => "Organizational",
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        organization(id: \"https://ror.org/00k4n6c32\") {
          name
          dataManagementPlans {
            totalCount
            registrationAgencies {
              id
              title
              count
            }
            licenses {
              id
              title
              count
            }
            languages {
              id
              title
              count
            }
            nodes {
              id
              types {
                resourceTypeGeneral
                resourceType
                schemaOrg
              }
              contributors {
                id
                name
                contributorType
              }
              registrationAgency {
                id
                name
              }
            }
          }
        }
      }"
    end

    it "returns all data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "name")).to eq("European Commission")
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "totalCount",
        ),
      ).to eq(2)
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "languages",
        ),
      ).to eq([{ "count" => 2, "id" => "de", "title" => "German" }])
      expect(
        response.dig("data", "organization", "dataManagementPlans", "licenses"),
      ).to eq([{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }])
      expect(
        response.dig("data", "organization", "dataManagementPlans", "nodes").
          length,
      ).to eq(2)
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "nodes",
          0,
          "registrationAgency",
        ),
      ).to eq("id" => "datacite", "name" => "DataCite")
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "nodes",
          0,
          "types",
        ),
      ).to eq(
        "resourceType" => "Data Management Plan",
        "resourceTypeGeneral" => "Text",
        "schemaOrg" => "ScholarlyArticle",
      )
      expect(
        response.dig(
          "data",
          "organization",
          "dataManagementPlans",
          "nodes",
          0,
          "contributors",
        ),
      ).to eq(
        [
          {
            "contributorType" => "Sponsor",
            "id" => "https://ror.org/00k4n6c32",
            "name" => "European Commission",
          },
        ],
      )
    end
  end

  describe "query data_management_plans by language", elasticsearch: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        language: "de",
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        dataManagementPlans(language: \"de\") {
          totalCount
          registrationAgencies {
            id
            title
            count
          }
          licenses {
            id
            title
            count
          }
          languages {
            id
            title
            count
          }
          nodes {
            id
            rights {
              rights
              rightsUri
              rightsIdentifier
            }
            language {
              id
              name
            }
            registrationAgency {
              id
              name
            }
          }
        }
      }"
    end

    it "returns all data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dataManagementPlans", "totalCount")).to eq(2)
      expect(
        response.dig("data", "dataManagementPlans", "registrationAgencies"),
      ).to eq([{ "count" => 2, "id" => "datacite", "title" => "DataCite" }])
      expect(response.dig("data", "dataManagementPlans", "licenses")).to eq(
        [{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }],
      )
      expect(response.dig("data", "dataManagementPlans", "nodes").length).to eq(
        2,
      )
      expect(
        response.dig("data", "dataManagementPlans", "nodes", 0, "rights"),
      ).to eq(
        [
          {
            "rights" => "Creative Commons Zero v1.0 Universal",
            "rightsIdentifier" => "cc0-1.0",
            "rightsUri" =>
              "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
          },
        ],
      )
      expect(
        response.dig(
          "data",
          "dataManagementPlans",
          "nodes",
          0,
          "registrationAgency",
        ),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query data_management_plans by license", elasticsearch: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        language: "de",
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        dataManagementPlans(license: \"cc0-1.0\") {
          totalCount
          registrationAgencies {
            id
            title
            count
          }
          languages {
            id
            title
            count
          }
          licenses {
            id
            title
            count
          }
          nodes {
            id
            registrationAgency {
              id
              name
            }
            language {
              id
              name
            }
            rights {
              rights
              rightsUri
              rightsIdentifier
            }
          }
        }
      }"
    end

    it "returns all data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dataManagementPlans", "totalCount")).to eq(2)
      expect(
        response.dig("data", "dataManagementPlans", "registrationAgencies"),
      ).to eq([{ "count" => 2, "id" => "datacite", "title" => "DataCite" }])
      expect(response.dig("data", "dataManagementPlans", "languages")).to eq(
        [{ "count" => 2, "id" => "de", "title" => "German" }],
      )
      expect(response.dig("data", "dataManagementPlans", "nodes").length).to eq(
        2,
      )
      expect(
        response.dig(
          "data",
          "dataManagementPlans",
          "nodes",
          0,
          "registrationAgency",
        ),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query data_management_plans by person", elasticsearch: true do
    let!(:data_management_plans) do
      create_list(
        :doi,
        3,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        aasm_state: "findable",
      )
    end
    let!(:data_management_plan) do
      create(
        :doi,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        aasm_state: "findable",
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
          },
        ],
      )
    end
    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        dataManagementPlans(userId: \"https://orcid.org/0000-0003-1419-2405\") {
          totalCount
          published {
            id
            title
            count
          }
          nodes {
            id
          }
        }
      }"
    end

    it "returns data_management_plans" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dataManagementPlans", "totalCount")).to eq(3)
      expect(response.dig("data", "dataManagementPlans", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "dataManagementPlans", "nodes").length).to eq(
        3,
      )
    end
  end

  describe "find data management plan with citations",
           elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) do
      create(
        :doi,
        client: client,
        types: {
          "resourceTypeGeneral" => "Text",
          "resourceType" => "Data Management Plan",
        },
        aasm_state: "findable",
      )
    end
    let(:source_doi) do
      create(
        :doi,
        client: client,
        types: { "resourceTypeGeneral" => "Dataset" },
        aasm_state: "findable",
      )
    end
    let(:source_doi2) do
      create(
        :doi,
        client: client,
        types: { "resourceTypeGeneral" => "Software" },
        aasm_state: "findable",
      )
    end
    let!(:citation_event) do
      create(
        :event_for_datacite_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2015-06-13T16:14:19Z",
      )
    end
    let!(:citation_event2) do
      create(
        :event_for_datacite_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi2.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2015-06-13T16:14:19Z",
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        dataManagementPlan(id: \"https://doi.org/#{
        doi.doi
      }\") {
          id
          partOf {
            nodes {
              id
            }
          }
          citations(resourceTypeId: \"Dataset\") {
            totalCount
            nodes {
              id
              type
            }
          }
        }
      }"
    end

    it "returns citations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dataManagementPlan", "id")).to eq(
        "https://handle.stage.datacite.org/#{doi.doi.downcase}",
      )
      expect(
        response.dig("data", "dataManagementPlan", "citations", "totalCount"),
      ).to eq(1)
    end
  end
end
