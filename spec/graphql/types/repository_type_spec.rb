# frozen_string_literal: true

require "rails_helper"

describe RepositoryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:re3dataId).of_type(types.ID) }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:url).of_type("Url") }
    it { is_expected.to have_field(:software).of_type("String") }
    it { is_expected.to have_field(:clientType).of_type("String") }
    it { is_expected.to have_field(:repositoryType).of_type("[String!]") }
    it { is_expected.to have_field(:certificate).of_type("[String!]") }
    it { is_expected.to have_field(:language).of_type("[String!]") }
    it { is_expected.to have_field(:issn).of_type("Issn") }

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

  describe "query repositories", elasticsearch: true do
    let!(:clients) { create_list(:client, 3, software: "Dataverse") }
    let!(:client) do
      create(:client, software: "Dataverse", re3data_id: "10.17616/R3XS37")
    end
    before do
      Client.import
      sleep 2
    end

    let(:query) do
      "query {
        repositories(first: 10) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          years {
            id
            title
            count
          }
          members {
            title
            count
          }
          software {
            id
            title
            count
          }
          certificates {
            id
            title
            count
          }
          clientTypes {
            id
            title
            count
          }
          repositoryTypes {
            id
            title
            count
          }
          nodes {
            id
            name
            alternateName
            re3dataId
          }
        }
      }"
    end

    it "returns repositories" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "repositories", "totalCount")).to eq(4)
      expect(response.dig("data", "repositories", "years")).to eq(
        [{ "count" => 4, "id" => "2020", "title" => "2020" }],
      )
      expect(response.dig("data", "repositories", "members")).to eq(
        [
          { "count" => 1, "title" => "My provider" },
          { "count" => 1, "title" => "My provider" },
          { "count" => 1, "title" => "My provider" },
          { "count" => 1, "title" => "My provider" },
        ],
      )
      expect(response.dig("data", "repositories", "software")).to eq(
        [{ "count" => 4, "id" => "dataverse", "title" => "Dataverse" }],
      )
      expect(response.dig("data", "repositories", "certificates")).to be_empty
      # expect(response.dig("data", "repositories", "clientTypes")).to eq([{"count"=>4, "id"=>"repository", "title"=>"Repository"}])
      # expect(response.dig("data", "repositories", "repositoryTypes")).to be_empty
      expect(response.dig("data", "repositories", "nodes").length).to eq(4)

      client1 = response.dig("data", "repositories", "nodes", 3)
      expect(client1.fetch("id")).to eq(client.uid)
      expect(client1.fetch("name")).to eq(client.name)
      expect(client1.fetch("alternateName")).to eq(client.alternate_name)
      expect(client1.fetch("re3dataId")).to eq("10.17616/R3XS37")
    end
  end

  describe "find repository", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "TESTC") }
    let(:client) do
      create(
        :client,
        symbol: "TESTC.TESTC", alternate_name: "ABC", provider: provider,
      )
    end
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:prefix) { create(:prefix) }
    let!(:client_prefixes) { create_list(:client_prefix, 3, client: client) }

    before do
      Provider.import
      Client.import
      Doi.import
      Prefix.import
      ClientPrefix.import
      sleep 3
    end

    let(:query) do
      "query {
        repository(id: \"testc.testc\") {
          id
          name
          alternateName
          datasets {
            totalCount
          }
          prefixes {
            totalCount
            years {
              id
              count
            }
            nodes {
              name
            }
          }
        }
      }"
    end

    it "returns repository" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "repository", "id")).to eq(client.uid)
      expect(response.dig("data", "repository", "name")).to eq("My data center")
      expect(response.dig("data", "repository", "alternateName")).to eq("ABC")

      expect(
        response.dig("data", "repository", "datasets", "totalCount"),
      ).to eq(1)

      expect(
        response.dig("data", "repository", "prefixes", "totalCount"),
      ).to eq(3)
      expect(response.dig("data", "repository", "prefixes", "years")).to eq(
        [{ "count" => 3, "id" => "2020" }],
      )
      expect(
        response.dig("data", "repository", "prefixes", "nodes").length,
      ).to eq(3)
      prefix1 = response.dig("data", "repository", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(client_prefixes.first.prefix_id)
    end
  end

  describe "find repository with citations", elasticsearch: true, vcr: true do
    let(:provider) { create(:provider, symbol: "TESTR") }
    let(:client) { create(:client, symbol: "TESTR.TESTR", provider: provider) }
    let(:doi) do
      create(
        :doi,
        client: client,
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
      Provider.import
      Client.import
      Event.import
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        repository(id: \"testr.testr\") {
          id
          name
          citationCount
          works {
            totalCount
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

    it "returns repository information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "repository", "id")).to eq("testr.testr")
      expect(response.dig("data", "repository", "name")).to eq("My data center")
      expect(response.dig("data", "repository", "citationCount")).to eq(2)
      expect(response.dig("data", "repository", "works", "totalCount")).to eq(3)
      expect(response.dig("data", "repository", "works", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(
        response.dig("data", "repository", "works", "resourceTypes"),
      ).to eq([{ "count" => 3, "id" => "dataset", "title" => "Dataset" }])
      expect(response.dig("data", "repository", "works", "nodes").length).to eq(
        3,
      )

      # work = response.dig("data", "repository", "works", "nodes", 0)
      # expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      # expect(work.dig("citationCount")).to eq(2)
    end
  end
end
