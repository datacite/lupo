require "rails_helper"

describe FunderType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "find funder", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable", funding_references:
      [{
        "funderIdentifier" => "https://doi.org/10.13039/501100009053",
        "funderIdentifierType" => "Crossref Funder ID",
        "funderName" => "The Wellcome Trust DBT India Alliance"
      }])
    }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
    let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

    before do
      Client.import
      Event.import
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        funder(id: "https://doi.org/10.13039/501100009053") {
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
            years {
              title
              count
            }
            resourceTypes {
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
      })
    end

    it "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funder", "id")).to eq("https://doi.org/10.13039/501100009053")
      expect(response.dig("data", "funder", "name")).to eq("The Wellcome Trust DBT India Alliance")
      expect(response.dig("data", "funder", "citationCount")).to eq(0)

      expect(response.dig("data", "funder", "works", "totalCount")).to eq(1)
      expect(Base64.urlsafe_decode64(response.dig("data", "funder", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(doi.uid)
      expect(response.dig("data", "funder", "works", "pageInfo", "hasNextPage")).to be false
      expect(response.dig("data", "funder", "works", "years")).to eq([{"count"=>1, "title"=>"2011"}])
      expect(response.dig("data", "funder", "works", "resourceTypes")).to eq([{"count"=>1, "title"=>"Dataset"}])
      expect(response.dig("data", "funder", "works", "nodes").length).to eq(1)

      work = response.dig("data", "funder", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig("citationCount")).to eq(2)
    end
  end

  describe "query funders", elasticsearch: true, vcr: true do
    let!(:dois) { create_list(:doi, 3, funding_references:
      [{
        "funderIdentifier" => "https://doi.org/10.13039/501100009053",
        "funderIdentifierType" => "DOI",
      }])
    }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        funders(query: "Wellcome Trust", first: 30, after: "Mg") {
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
              years {
                title
                count
              }
            }
          }
        }
      })
    end

    it "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funders", "totalCount")).to eq(4)
      expect(response.dig("data", "funders", "pageInfo", "endCursor")).to eq("Mw")
      # expect(response.dig("data", "funders", "pageInfo", "hasNextPage")).to eq(false)
      expect(response.dig("data", "funders", "nodes").length).to eq(2)
      
      funder = response.dig("data", "funders", "nodes", 0)
      expect(funder.fetch("id")).to eq("https://doi.org/10.13039/501100009053")
      expect(funder.fetch("name")).to eq("The Wellcome Trust DBT India Alliance")
      expect(funder.fetch("alternateName")).to eq(["India Alliance", "WTDBT India Alliance", "Wellcome Trust/DBT India Alliance", "Wellcome Trust DBt India Alliance"])
      # expect(funder.dig("works", "totalCount")).to eq(3)
      # expect(funder.dig("works", "years")).to eq([{"count"=>3, "title"=>"2011"}])
    end
  end

  describe "query funders national", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        funders(query: "national", first: 10, after: "OA") {
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
      })
    end

    it "returns funder information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "funders", "totalCount")).to eq(1100)
      expect(response.dig("data", "funders", "pageInfo", "endCursor")).to eq("OQ")
      expect(response.dig("data", "funders", "pageInfo", "hasNextPage")).to eq(true)
      expect(response.dig("data", "funders", "nodes").length).to eq(10)
      
      funder = response.dig("data", "funders", "nodes", 0)
      expect(funder.fetch("id")).to eq("https://doi.org/10.13039/100008725")
      expect(funder.fetch("name")).to eq("Agencia Nacional de Investigación e Innovación")
      expect(funder.fetch("alternateName")).to eq(["ANII", "Agência Nacional para a Investigação e Inovação", "National Agency for Research and Innovation"])
      expect(funder.dig("address", "country")).to eq("Uruguay") 
    end
  end
end
