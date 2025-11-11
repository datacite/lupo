# frozen_string_literal: true

require "rails_helper"

describe FunderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it do
      is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal")
    end
    it do
      is_expected.to have_field(:publications).of_type(
        "PublicationConnectionWithTotal",
      )
    end
    it do
      is_expected.to have_field(:softwares).of_type(
        "SoftwareConnectionWithTotal",
      )
    end
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "find funder", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) do
      create(
        :doi,
        client: client,
        aasm_state: "findable",
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100009053",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "The Wellcome Trust DBT India Alliance",
          },
        ],
      )
    end
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
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
        occurred_at: "2016-06-13T16:14:19Z",
      )
    end

    before do
      Client.import
      Event.import
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        funder(id: \"https://doi.org/10.13039/501100009053\") {
          id
          name
          alternateName
          citationCount
          viewCount
          downloadCount
          works {
            totalCount
            pageInfo {
              endCursor
              hasNextPage
            }
            published {
              id
              title
              count
            }
            resourceTypes {
              id
              title
              count
            }
            nodes {
              id
              titles {
                title
              }
              citationCount
            }
          }
        }
      }"
    end

    xit "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funder", "id")).to eq(
        "https://doi.org/10.13039/501100009053",
      )
      expect(response.dig("data", "funder", "name")).to eq(
        "The Wellcome Trust DBT India Alliance",
      )
      expect(response.dig("data", "funder", "citationCount")).to eq(2)
      expect(response.dig("data", "funder", "viewCount")).to eq(0)
      expect(response.dig("data", "funder", "downloadCount")).to eq(0)

      expect(response.dig("data", "funder", "works", "totalCount")).to eq(1)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "funder", "works", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(doi.uid)
      expect(
        response.dig("data", "funder", "works", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "funder", "works", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "funder", "works", "resourceTypes")).to eq(
        [{ "count" => 1, "id" => "dataset", "title" => "Dataset" }],
      )
      expect(response.dig("data", "funder", "works", "nodes").length).to eq(1)

      work = response.dig("data", "funder", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
      expect(work.dig("citationCount")).to eq(2)
    end
  end

  describe "query funders", elasticsearch: true, vcr: true do
    let!(:dois) do
      create_list(
        :doi,
        3,
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/100010269",
            "funderIdentifierType" => "DOI",
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        funders(query: \"Wellcome Trust\", first: 30, after: \"Mg\") {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            name
            alternateName
            works {
              totalCount
              published {
                id
                title
                count
              }
            }
          }
        }
      }"
    end

    it "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funders", "totalCount")).to eq(4)
      expect(response.dig("data", "funders", "pageInfo", "endCursor")).to eq(
        "Mw",
      )
      # expect(response.dig("data", "funders", "pageInfo", "hasNextPage")).to eq(false)
      expect(response.dig("data", "funders", "nodes").length).to eq(2)

      funder = response.dig("data", "funders", "nodes", 0)
      expect(funder.fetch("id")).to eq("https://doi.org/10.13039/100010269")
      expect(funder.fetch("name")).to eq("Wellcome Trust")
      expect(funder.fetch("alternateName")).to eq(
        ["The Wellcome Trust", "WT", "Wellcome"],
      )
      # expect(funder.dig("works", "totalCount")).to eq(3)
      # expect(funder.dig("works", "years")).to eq([{"count"=>3, "title"=>"2011"}])
    end
  end

  describe "query funders national", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        funders(query: \"national\", first: 10, after: \"OA\") {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            name
            alternateName
            address {
              country
            }
          }
        }
      }"
    end

    it "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funders", "totalCount")).to eq(1_144)
      expect(response.dig("data", "funders", "pageInfo", "endCursor")).to eq(
        "OQ",
      )
      expect(response.dig("data", "funders", "pageInfo", "hasNextPage")).to eq(
        true,
      )
      expect(response.dig("data", "funders", "nodes").length).to eq(10)

      funder = response.dig("data", "funders", "nodes", 0)
      expect(funder.fetch("id")).to eq("https://doi.org/10.13039/100000051")
      expect(funder.fetch("name")).to eq(
        "National Human Genome Research Institute",
      )
      expect(funder.fetch("alternateName")).to eq(%w[NHGRI])
      expect(funder.dig("address", "country")).to eq("United States")
    end
  end
end
