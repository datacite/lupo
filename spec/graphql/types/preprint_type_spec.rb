# frozen_string_literal: true

require "rails_helper"

describe PreprintType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query preprints", elasticsearch: true do
    let!(:preprints) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "Preprint"
        },
        agency: "datacite",
        aasm_state: "findable",
      )
    end
    let!(:posted_contents) do
      create_list(
        :doi,
        2,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent"
        },
        agency: "crossref",
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
        preprints {
          totalCount
          registrationAgencies {
            id
            title
            count
          }
          nodes {
            id
            type
            registrationAgency {
              id
              name
            }
          }
        }
      }"
    end

    it "returns all preprints" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "preprints", "totalCount")).to eq(4)
      expect(response.dig("data", "preprints", "registrationAgencies")).to eq(
        [
          { "count" => 2, "id" => "crossref", "title" => "Crossref" },
          { "count" => 2, "id" => "datacite", "title" => "DataCite" },
        ],
      )
      expect(response.dig("data", "preprints", "nodes").length).to eq(4)
      expect(response.dig("data", "preprints", "nodes", 0, "id")).to eq(
        @dois.first.identifier,
      )
      expect(response.dig("data", "preprints", "nodes", 0, "type")).to eq(
        "Preprint",
      )
      # expect(response.dig("data", "preprints", "nodes", 0, "registrationAgency")).to eq("id"=>"datacite", "name"=>"DataCite")
    end
  end

  describe "query preprints by person", elasticsearch: true do
    let!(:preprints) do
      create_list(
        :doi,
        3,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent"
        },
        aasm_state: "findable",
      )
    end
    let!(:preprint) do
      create(
        :doi,
        types: {
          "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent"
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
      @dois = Doi.query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        preprints(userId: \"https://orcid.org/0000-0003-1419-2405\") {
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

    it "returns preprints" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "preprints", "totalCount")).to eq(3)
      expect(response.dig("data", "preprints", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "preprints", "nodes").length).to eq(3)
      # expect(response.dig("data", "preprints", "nodes", 0, "id")).to eq(@dois.first.identifier)
    end
  end
end
