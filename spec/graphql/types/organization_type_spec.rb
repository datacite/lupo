require "rails_helper"

describe OrganizationType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:wikipediaUrl).of_type("Url") }
    it { is_expected.to have_field(:twitter).of_type("String") }
    it { is_expected.to have_field(:inception).of_type("ISO8601DateTime") }
    it { is_expected.to have_field(:geolocation).of_type("GeolocationPoint") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:identifiers).of_type("[Identifier!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithTotal") }
    it { is_expected.to have_field(:softwares).of_type("SoftwareConnectionWithTotal") }
    it { is_expected.to have_field(:works).of_type("WorkConnectionWithTotal") }
  end

  describe "find organization", elasticsearch: true, vcr: true do
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
    let!(:funder_doi) { create(:doi, aasm_state: "findable", funding_references:
      [{
        "funderIdentifier" => "https://doi.org/10.13039/501100000735",
        "funderIdentifierType" => "Crossref Funder ID",
        "funderName" => "University of Cambridge"
      }])
    }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        organization(id: "https://ror.org/013meh722") {
          id
          name
          alternateName
          description
          wikipediaUrl
          twitter
          inception
          geolocation {
            pointLongitude
            pointLatitude
          }
          identifiers {
            identifier
            identifierType
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
              title
              count
            }
            nodes {
              id
              titles {
                title
              }
            }
          }
        }
      })
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq("https://ror.org/013meh722")
      expect(response.dig("data", "organization", "name")).to eq("University of Cambridge")
      expect(response.dig("data", "organization", "alternateName")).to eq(["Cambridge University"])
      expect(response.dig("data", "organization", "description")).to eq("Collegiate public research university in Cambridge, England, United Kingdom")
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq("http://en.wikipedia.org/wiki/University_of_Cambridge")
      expect(response.dig("data", "organization", "twitter")).to eq("Cambridge_Uni")
      expect(response.dig("data", "organization", "inception")).to eq("1209-01-01T00:00:00Z")
      expect(response.dig("data", "organization", "geolocation")).to eq("pointLatitude"=>52.205277777778, "pointLongitude"=>0.11722222222222)
      expect(response.dig("data", "organization", "citationCount")).to eq(0)
      expect(response.dig("data", "organization", "identifiers").count).to eq(40)
      expect(response.dig("data", "organization", "identifiers").first).to eq("identifier"=>"10.13039/501100000735", "identifierType"=>"fundref")
      expect(response.dig("data", "organization", "identifiers").last).to eq("identifier"=>"7288046", "identifierType"=>"geonames")

      expect(response.dig("data", "organization", "works", "totalCount")).to eq(2)
      expect(response.dig("data", "organization", "works", "published")).to eq([{"count"=>2, "id"=>"2011", "title"=>"2011"}])
      expect(response.dig("data", "organization", "works", "resourceTypes")).to eq([{"count"=>2, "title"=>"Dataset"}])
      expect(response.dig("data", "organization", "works", "nodes").length).to eq(2)

      work = response.dig("data", "organization", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
    end
  end

  describe "find organization not found", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        organization(id: "https://ror.org/xxxx") {
          id
          name
          alternateName
          identifiers {
            identifier
            identifierType
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
              title
              count
            }
            nodes {
              id
              titles {
                title
              }
            }
          }
        }
      })
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq([{"locations"=>[{"column"=>9, "line"=>2}], "message"=>"Record not found", "path"=>["organization"]}])
    end
  end

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
            types
            address {
              country
            }
            alternateName
            url
            wikipediaUrl
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
      expect(organization.fetch("types")).to eq(["Education"])
      expect(organization.fetch("address")).to eq("country"=>"United Kingdom")
      expect(organization.fetch("alternateName")).to eq(["Cambridge University"])
      expect(organization.fetch("url")).to eq(["http://www.cam.ac.uk/"])
      expect(organization.fetch("wikipediaUrl")).to eq("http://en.wikipedia.org/wiki/University_of_Cambridge")

      expect(organization.fetch("identifiers").length).to eq(38)
      expect(organization.fetch("identifiers").last).to eq("identifier"=>"0000000121885934", "identifierType"=>"isni")

      expect(organization.dig("works", "totalCount")).to eq(1)
      expect(organization.dig("works", "published")).to eq([{"count"=>1, "id"=>"2011", "title"=>"2011"}])
    end
  end

  describe "query organizations with umlaut", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        organizations(query: "münster") {
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
            types
            address {
              country
            }
            alternateName
            url
            wikipediaUrl
            identifiers {
              identifier
              identifierType
            }
          }
        }
      })
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organizations", "totalCount")).to eq(10)      
      expect(response.dig("data", "organizations", "types").length).to eq(5)
      expect(response.dig("data", "organizations", "types").first).to eq("count"=>4, "id"=>"education", "title"=>"Education")
      expect(response.dig("data", "organizations", "countries").length).to eq(1)
      expect(response.dig("data", "organizations", "countries").first).to eq("count"=>10, "id"=>"de", "title"=>"Germany")
      expect(response.dig("data", "organizations", "nodes").length).to eq(10)
      organization = response.dig("data", "organizations", "nodes", 0)

      expect(organization.fetch("id")).to eq("https://ror.org/01856cw59")
      expect(organization.fetch("name")).to eq("University Hospital Münster")
      expect(organization.fetch("types")).to eq(["Healthcare"])
      expect(organization.fetch("address")).to eq("country"=>"Germany")
      expect(organization.fetch("alternateName")).to eq(["UKM"])
      expect(organization.fetch("url")).to eq(["http://klinikum.uni-muenster.de/"])
      expect(organization.fetch("wikipediaUrl")).to be_nil

      expect(organization.fetch("identifiers").length).to eq(2)
      expect(organization.fetch("identifiers").last).to eq("identifier"=>"0000000405514246", "identifierType"=>"isni")
    end
  end

  describe "query organizations by type", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        organizations(types: "government", country: "de", after: "MQ") {
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
            types
            address {
              country
            }
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

      expect(response.dig("data", "organizations", "totalCount")).to eq(182)
      expect(response.dig("data", "organizations", "pageInfo", "endCursor")).to eq("Mg")
      expect(response.dig("data", "organizations", "pageInfo", "hasNextPage")).to be true
      
      expect(response.dig("data", "organizations", "types").length).to eq(1)
      expect(response.dig("data", "organizations", "types").first).to eq("count"=>182, "id"=>"government", "title"=>"Government")
      expect(response.dig("data", "organizations", "countries").length).to eq(1)
      expect(response.dig("data", "organizations", "countries").first).to eq("count"=>182, "id"=>"de", "title"=>"Germany")
      expect(response.dig("data", "organizations", "nodes").length).to eq(20)
      organization = response.dig("data", "organizations", "nodes", 0)
      expect(organization.fetch("id")).to eq("https://ror.org/04bqwzd17")
      expect(organization.fetch("name")).to eq("Bayerisches Landesamt für Gesundheit und Lebensmittelsicherheit")
      expect(organization.fetch("types")).to eq(["Government"])
      expect(organization.fetch("address")).to eq("country"=>"Germany")
      expect(organization.fetch("alternateName")).to eq(["LGL"])
      expect(organization.fetch("identifiers").length).to eq(2)
      expect(organization.fetch("identifiers").first).to eq("identifier"=>"grid.414279.d", "identifierType"=>"grid")

      expect(organization.dig("works", "totalCount")).to eq(0)
    end
  end
end
