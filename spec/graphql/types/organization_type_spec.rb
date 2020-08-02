require "rails_helper"

describe OrganizationType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  # describe "find organization", elasticsearch: true, vcr: true do
  #   let(:client) { create(:client) }
  #   let!(:doi) { create(:doi, client: client, aasm_state: "findable", creators:
  #     [{
  #       "familyName" => "Garza",
  #       "givenName" => "Kristian",
  #       "name" => "Garza, Kristian",
  #       "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
  #       "nameType" => "Personal",
  #       "affiliation": [
  #         {
  #           "name": "University of Cambridge",
  #           "affiliationIdentifier": "https://ror.org/013meh722",
  #           "affiliationIdentifierScheme": "ROR"
  #         },
  #       ]
  #     }])
  #   }
  #   let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
  #   let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
  #   let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
  #   let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

  #   before do
  #     Client.import
  #     Event.import
  #     Doi.import
  #     sleep 2
  #   end

  #   let(:query) do
  #     %(query {
  #       organization(id: "https://ror.org/013meh722") {
  #         id
  #         name
  #         alternateName
  #         citationCount
  #         viewCount
  #         downloadCount
  #         works {
  #           totalCount
  #           published {
  #             id
  #             title
  #             count
  #           }
  #           resourceTypes {
  #             title
  #             count
  #           }
  #           nodes {
  #             id
  #             titles {
  #               title
  #             }
  #             citationCount
  #           }
  #         }
  #       }
  #     })
  #   end

  #   it "returns organization information" do
  #     response = LupoSchema.execute(query).as_json

  #     expect(response.dig("data", "organization", "id")).to eq("https://ror.org/013meh722")
  #     expect(response.dig("data", "organization", "name")).to eq("University of Cambridge")
  #     expect(response.dig("data", "organization", "alternateName")).to eq(["Cambridge University"])
  #     expect(response.dig("data", "organization", "citationCount")).to eq(0)
  #     expect(response.dig("data", "organization", "works", "totalCount")).to eq(1)
  #     expect(response.dig("data", "organization", "works", "published")).to eq([{"count"=>1, "id"=>"2011", "title"=>"2011"}])
  #     expect(response.dig("data", "organization", "works", "resourceTypes")).to eq([{"count"=>1, "title"=>"Dataset"}])
  #     expect(response.dig("data", "organization", "works", "nodes").length).to eq(1)

  #     work = response.dig("data", "organization", "works", "nodes", 0)
  #     expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
  #     expect(work.dig("citationCount")).to eq(2)
  #   end
  # end

  describe "query organizations", elasticsearch: true, vcr: true do
    let!(:dois) { create_list(:doi, 3) }
    let!(:doi) { create(:doi, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
        "affiliation": [
          {
            "name": "University of Cambridge",
            "affiliationIdentifier": "https://ror.org/013meh722",
            "affiliationIdentifierScheme": "ROR"
          },
        ]
      }])
    }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        organizations(query: "Cambridge University", after: "MQ") {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          types {
            id
            title
            count
          }
          countries {
            id
            title
            count
          }
          nodes {
            id
            name
            alternateName
            identifiers {
              identifier
              identifierType
            }
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

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organizations", "totalCount")).to eq(10790)
      expect(response.dig("data", "organizations", "pageInfo", "endCursor")).to eq("Mg")
      expect(response.dig("data", "organizations", "pageInfo", "hasNextPage")).to be true
      
      expect(response.dig("data", "organizations", "types").length).to eq(8)
      expect(response.dig("data", "organizations", "types").first).to eq("count"=>9630, "id"=>"education", "title"=>"Education")
      expect(response.dig("data", "organizations", "countries").length).to eq(10)
      expect(response.dig("data", "organizations", "countries").first).to eq("count"=>1771, "id" => "us", "title"=>"United States of America")
      expect(response.dig("data", "organizations", "nodes").length).to eq(20)
      organization = response.dig("data", "organizations", "nodes", 0)
      expect(organization.fetch("id")).to eq("https://ror.org/013meh722")
      expect(organization.fetch("name")).to eq("University of Cambridge")
      expect(organization.fetch("alternateName")).to eq(["Cambridge University"])
      expect(organization.fetch("identifiers").length).to eq(38)
      expect(organization.fetch("identifiers").last).to eq("identifier"=>"http://en.wikipedia.org/wiki/University_of_Cambridge", "identifierType"=>"wikipedia")

      expect(organization.dig("works", "totalCount")).to eq(1)
      expect(organization.dig("works", "published")).to eq([{"count"=>1, "id"=>"2011", "title"=>"2011"}])
    end
  end
end
