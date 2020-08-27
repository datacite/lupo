require "rails_helper"

describe PersonType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:givenName).of_type("String") }
    it { is_expected.to have_field(:familyName).of_type("String") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:links).of_type("[Link!]") }
    it { is_expected.to have_field(:identifiers).of_type("[Identifier!]") }
    it { is_expected.to have_field(:country).of_type("Country") }
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
          description
          links {
            name
            url
          }
          identifiers {
            identifier
            identifierType
            identifierUrl
          }
          country {
            id
            name
          }
          citationCount
          viewCount
          downloadCount
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
      })
    end

    it "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq("https://orcid.org/0000-0003-3484-6875")
      expect(response.dig("data", "person", "name")).to eq("K. J. Garza")
      expect(response.dig("data", "person", "givenName")).to eq("Kristian")
      expect(response.dig("data", "person", "familyName")).to eq("Garza")
      expect(response.dig("data", "person", "alternateName")).to eq(["Kristian Javier Garza Gutierrez"])
      expect(response.dig("data", "person", "description")).to be_nil
      expect(response.dig("data", "person", "links")).to eq([{"name"=>"Mendeley profile", "url"=>"https://www.mendeley.com/profiles/kristian-g/"}])
      expect(response.dig("data", "person", "identifiers")).to eq([{"identifier"=>"kjgarza", "identifierType"=>"GitHub", "identifierUrl"=>"https://github.com/kjgarza"}])
      expect(response.dig("data", "person", "country")).to eq("id"=>"DE", "name"=>"Germany")
      expect(response.dig("data", "person", "citationCount")).to eq(0)
      expect(response.dig("data", "person", "works", "totalCount")).to eq(1)
      expect(response.dig("data", "person", "works", "published")).to eq([{"count"=>1, "id"=>"2011", "title"=>"2011"}])
      expect(response.dig("data", "person", "works", "resourceTypes")).to eq([{"count"=>1, "id"=>"dataset", "title"=>"Dataset"}])
      expect(response.dig("data", "person", "works", "nodes").length).to eq(1)

      work = response.dig("data", "person", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig("citationCount")).to eq(2)
    end
  end

  describe "find person not found", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        person(id: "https://orcid.org/xxxx") {
          id
          name
          givenName
          familyName
          alternateName
          description
          links {
            name
            url
          }
          identifiers {
            identifier
            identifierType
            identifierUrl
          }
          country {
            id
            name
          }
          citationCount
          viewCount
          downloadCount
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
      })
    end

    it "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq([{"locations"=>[{"column"=>9, "line"=>2}], "message"=>"Record not found", "path"=>["person"]}])
    end
  end

  describe "find person account locked", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        person(id: "https://orcid.org/0000-0003-1315-5960") {
          id
          name
          givenName
          familyName
          alternateName
          description
          links {
            name
            url
          }
          identifiers {
            identifier
            identifierType
            identifierUrl
          }
          country {
            id
            name
          }
          citationCount
          viewCount
          downloadCount
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
      })
    end

    it "returns error" do
      response = LupoSchema.execute(query).as_json
      puts response
      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq([{"locations"=>[{"column"=>9, "line"=>2}], "message"=>"409 Conflict: The ORCID record is locked and cannot be edited. ORCID https://orcid.org/0000-0003-1315-5960", "path"=>["person"]}])
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
      })
    end

    it "returns people information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "people", "totalCount")).to eq(261)
      expect(response.dig("data", "people", "pageInfo", "endCursor")).to eq("NQ")
      #expect(response.dig("data", "people", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "people", "nodes").length).to eq(50)

      person = response.dig("data", "people", "nodes", 0)
      expect(person.fetch("id")).to eq("https://orcid.org/0000-0001-8624-4484")
      expect(person.fetch("name")).to eq("Nelida Villasenor")
      expect(person.fetch("givenName")).to eq("Nelida")
      expect(person.fetch("familyName")).to eq("Villasenor")
      expect(person.fetch("alternateName")).to eq(["Nélida R. Villaseñor"])
    end
  end

  describe "query people with error", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        people(query: "container.identifier:2658-719X") {
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
      })
    end

    it "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors", 0, "message")).to eq("org.apache.solr.client.solrj.impl.HttpSolrClient.RemoteSolrException Full validation error: Error from server at http://solr-loc.orcid.org/solr/profile: undefined field container.identifier")
    end
  end
end
