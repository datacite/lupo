require "rails_helper"

describe PersonType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:givenName).of_type("String") }
    it { is_expected.to have_field(:familyName).of_type("String") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "find person", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
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
      sleep 3
    end

    let(:query) do
      %(query {
        person(id: "https://orcid.org/0000-0003-3484-6875") {
          id
          name
          givenName
          familyName
          alternateName
          affiliation {
            name
          }
          citationCount
          viewCount
          downloadCount
          works {
            totalCount
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

    it "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq("https://orcid.org/0000-0003-3484-6875")
      expect(response.dig("data", "person", "name")).to eq("K. J. Garza")
      expect(response.dig("data", "person", "givenName")).to eq("Kristian")
      expect(response.dig("data", "person", "familyName")).to eq("Garza")
      expect(response.dig("data", "person", "alternateName")).to eq([])
      expect(response.dig("data", "person", "affiliation")).to eq([])
      expect(response.dig("data", "person", "citationCount")).to eq(0)
      expect(response.dig("data", "person", "works", "totalCount")).to eq(1)
      expect(response.dig("data", "person", "works", "years")).to eq([{"count"=>1, "title"=>"2011"}])
      expect(response.dig("data", "person", "works", "resourceTypes")).to eq([{"count"=>1, "title"=>"Dataset"}])
      expect(response.dig("data", "person", "works", "nodes").length).to eq(1)

      work = response.dig("data", "person", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig("citationCount")).to eq(2)
    end
  end

  describe "query people", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        people(query: "Fenner", first: 50, after: "NA") {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            name
            givenName
            familyName
            alternateName
            affiliation {
              name
            }
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

    it "returns people information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "people", "totalCount")).to eq(247)
      expect(response.dig("data", "people", "pageInfo", "endCursor")).to eq("NQ")
      #expect(response.dig("data", "people", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "people", "nodes").length).to eq(47)

      person = response.dig("data", "people", "nodes", 0)
      expect(person.fetch("id")).to eq("https://orcid.org/0000-0003-0854-2034")
      expect(person.fetch("name")).to eq("Martin Westgate")
      expect(person.fetch("givenName")).to eq("Martin")
      expect(person.fetch("familyName")).to eq("Westgate")
      expect(person.fetch("alternateName")).to eq([])
      expect(person.fetch("affiliation")).to eq([{"name"=>"The Australian National University"}])
    end
  end
end
