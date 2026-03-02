# frozen_string_literal: true

require "rails_helper"

describe BookType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query books", elasticsearch: true do
    let!(:books) do
      create_list(
        :doi,
        3,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Book" },
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        books {
          totalCount
          nodes {
            id
          }
        }
      }"
    end

    it "returns all books" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "books", "totalCount")).to eq(3)
      expect(response.dig("data", "books", "nodes").length).to eq(3)
      expect(response.dig("data", "books", "nodes", 0, "id")).to eq(
        @dois.first.identifier,
      )
    end
  end

  describe "query books by person", elasticsearch: true do
    let!(:books) do
      create_list(
        :doi,
        3,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Book" },
        aasm_state: "findable",
      )
    end
    let!(:book) do
      create(
        :doi,
        types: { "resourceTypeGeneral" => "Text", "resourceType" => "Book" },
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
        books(userId: \"https://orcid.org/0000-0003-1419-2405\") {
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

    it "returns books" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "books", "totalCount")).to eq(3)
      expect(response.dig("data", "books", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "books", "nodes").length).to eq(3)
      # expect(response.dig("data", "books", "nodes", 0, "id")).to eq(@dois.first.identifier)
    end
  end
end
