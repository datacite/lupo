# frozen_string_literal: true

require "rails_helper"

describe DissertationType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query dissertations", elasticsearch: true do
    let!(:datacite_dissertations) do
      create_list(
        :doi,
        2,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" },
        language: "de",
        aasm_state: "findable",
      )
    end
    let!(:crossref_dissertations) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation"
        },
        agency: "Crossref",
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
        dissertations(registrationAgency: \"datacite\") {
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

    it "returns all dissertations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dissertations", "totalCount")).to eq(2)
      expect(
        response.dig("data", "dissertations", "registrationAgencies"),
      ).to eq([{ "count" => 2, "id" => "datacite", "title" => "DataCite" }])
      expect(response.dig("data", "dissertations", "licenses")).to eq(
        [{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }],
      )
      expect(response.dig("data", "dissertations", "nodes").length).to eq(2)
      # expect(response.dig("data", "dissertations", "nodes", 0, "id")).to eq(@dois.first.identifier)
      expect(
        response.dig("data", "dissertations", "nodes", 0, "registrationAgency"),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query dissertations by license", elasticsearch: true do
    let!(:datacite_dissertations) do
      create_list(
        :doi,
        2,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" },
        aasm_state: "findable",
      )
    end
    let!(:crossref_dissertations) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation"
        },
        agency: "Crossref",
        rights_list: [],
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
        dissertations(license: \"cc0-1.0\") {
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
          nodes {
            id
            rights {
              rights
              rightsUri
              rightsIdentifier
            }
            registrationAgency {
              id
              name
            }
          }
        }
      }"
    end

    it "returns all dissertations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dissertations", "totalCount")).to eq(2)
      expect(
        response.dig("data", "dissertations", "registrationAgencies"),
      ).to eq([{ "count" => 2, "id" => "datacite", "title" => "DataCite" }])
      expect(response.dig("data", "dissertations", "licenses")).to eq(
        [{ "count" => 2, "id" => "cc0-1.0", "title" => "CC0-1.0" }],
      )
      expect(response.dig("data", "dissertations", "nodes").length).to eq(2)
      # expect(response.dig("data", "dissertations", "nodes", 0, "id")).to eq(@dois.first.identifier)
      expect(response.dig("data", "dissertations", "nodes", 0, "rights")).to eq(
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
        response.dig("data", "dissertations", "nodes", 0, "registrationAgency"),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query dissertations by license", elasticsearch: true do
    let!(:datacite_dissertations) do
      create_list(
        :doi,
        2,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" },
        language: "de",
        aasm_state: "findable",
      )
    end
    let!(:crossref_dissertations) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation"
        },
        agency: "Crossref",
        rights_list: [],
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
        dissertations(language: \"de\") {
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
          }
        }
      }"
    end

    it "returns all dissertations" do
      response = LupoSchema.execute(query).as_json
    
      expect(response.dig("data", "dissertations", "totalCount")).to eq(2)
      expect(
        response.dig("data", "dissertations", "registrationAgencies"),
      ).to eq([{ "count" => 2, "id" => "datacite", "title" => "DataCite" }])
      expect(response.dig("data", "dissertations", "languages")).to eq(
        [{ "count" => 2, "id" => "de", "title" => "German" }],
      )
      expect(response.dig("data", "dissertations", "nodes").length).to eq(2)
      # expect(response.dig("data", "dissertations", "nodes", 0, "id")).to eq(@dois.first.identifier)
      expect(
        response.dig("data", "dissertations", "nodes", 0, "registrationAgency"),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query dissertations by person", elasticsearch: true do
    let!(:dissertations) do
      create_list(
        :doi,
        3,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation"
        },
        aasm_state: "findable",
        contributors: [
          {
            "name" => "Freie Universität Berlin",
            "contributorType" => "HostingInstitution",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/046ak2485",
                "nameIdentifierScheme" => "ROR",
                "schemeUri" => "https://ror.org",
              },
            ],
            "nameType" => "Organizational",
          },
        ],
      )
    end
    let!(:dissertation) do
      create(
        :doi,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation"
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
        dissertations(userId: \"https://orcid.org/0000-0003-1419-2405\") {
          totalCount
          published {
            id
            title
            count
          }
          nodes {
            id
            dataManagers: contributors(contributorType: \"DataManager\") {
              id
              type
              name
              contributorType
            }
            hostingInstitution: contributors(contributorType: \"HostingInstitution\") {
              id
              type
              name
              contributorType
            }
            contributors {
              id
              type
              name
              contributorType
            }
          }
        }
      }"
    end

    it "returns dissertations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dissertations", "totalCount")).to eq(3)
      expect(response.dig("data", "dissertations", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "dissertations", "nodes").length).to eq(3)
      expect(
        response.dig("data", "dissertations", "nodes", 0, "dataManagers"),
      ).to eq([])
      expect(
        response.dig("data", "dissertations", "nodes", 0, "hostingInstitution"),
      ).to eq(
        [
          {
            "contributorType" => "HostingInstitution",
            "id" => "https://ror.org/046ak2485",
            "name" => "Freie Universität Berlin",
            "type" => "Organization",
          },
        ],
      )
      expect(
        response.dig("data", "dissertations", "nodes", 0, "contributors"),
      ).to eq(
        [
          {
            "contributorType" => "HostingInstitution",
            "id" => "https://ror.org/046ak2485",
            "name" => "Freie Universität Berlin",
            "type" => "Organization",
          },
        ],
      )
    end
  end
end
