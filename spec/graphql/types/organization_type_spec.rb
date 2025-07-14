# frozen_string_literal: true

require "rails_helper"

describe OrganizationType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:country).of_type("Country") }
    it { is_expected.to have_field(:wikipediaUrl).of_type("Url") }
    it { is_expected.to have_field(:twitter).of_type("String") }
    it { is_expected.to have_field(:inceptionYear).of_type("Int") }
    it { is_expected.to have_field(:geolocation).of_type("GeolocationPoint") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:identifiers).of_type("[Identifier!]") }
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

  describe "find organization", elasticsearch: true, vcr: true do
    let!(:creator_doi) do
      create(
        :doi,
        aasm_state: "findable",
        titles: [
          { title: "Related to org thorugh creator affiliation" }
        ],
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
            "affiliation": [
              {
                "name": "University of Cambridge",
                "affiliationIdentifier": "https://ror.org/013meh722",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
          },
        ],
      )
    end
    let!(:contributor_doi) do
      create(
        :doi,
        aasm_state: "findable",
        titles: [
          { title: "Related to org thorugh contributor affiliation" }
        ],
        contributors: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "contributorType" => "DataManager",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation": [
              {
                "name": "University of Cambridge",
                "affiliationIdentifier": "https://ror.org/013meh722",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
          },
        ],
      )
    end
    let!(:funder_doi) do
      create(
        :doi,
        aasm_state: "findable",
        titles: [
          { title: "Related to org through funder" }
        ],
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100000735",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "University of Cambridge",
          },
        ],
      )
    end
    let!(:publisher_doi) do
      create(
        :doi,
        aasm_state: "findable",
        titles: [
          { title: "Related to org through publisher identifier" }
        ],
        publisher: {
          "publisherIdentifier": "https://ror.org/013meh722",
          "publisherIdentifierScheme": "ROR",
          "name": "University of Cambridge",
        },
      )
    end

    let(:provider) do
      create(:provider, symbol: "LPSW", ror_id: "https://ror.org/013meh722")
    end
    let(:client) { create(:client, provider: provider) }
    let!(:member_doi) { create(:doi,
                               aasm_state: "findable",
                               titles: [
                                 { title: "Related to org through member" }
                               ],
                               client: client) }
    let!(:related_through_dmp_doi) {
      create(
        :doi,
        aasm_state: "findable",
        titles: [
          { title: "Related through DMP" }
        ],
        related_identifiers: [
          {
          "relatedIdentifier": creator_doi.doi,
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
          "resourceTypeGeneral": "OutputManagementPlan",
        }
      ])
    }
    let(:unrelated_doi) {
      create(:doi)
    }
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        organization(id: \"https://ror.org/013meh722\") {
          id
          memberId
          memberRoleId
          memberRoleName
          name
          alternateName
          wikipediaUrl
          twitter
          inceptionYear
          country {
            id
            name
          }
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
              doi
              titles {
                title
              }
            }
          }
        }
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "organization", "memberId")).to eq("lpsw")
      expect(response.dig("data", "organization", "memberRoleId")).to eq(
        "direct_member",
      )
      expect(response.dig("data", "organization", "memberRoleName")).to eq(
        "Direct Member",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )
      expect(response.dig("data", "organization", "twitter")).to eq(
        "Cambridge_Uni",
      )
      expect(response.dig("data", "organization", "inceptionYear")).to eq(1_209)
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => 52.205355979757925,
        "pointLongitude" => 0.11315726963968827,
      )
      expect(response.dig("data", "organization", "citationCount")).to eq(0)
      expect(response.dig("data", "organization", "identifiers").count).to eq(
        53,
      )
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "10.13039/501100000735", "identifierType" => "fundref",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(response.dig("data", "organization", "works", "totalCount")).to eq(
        6
      )
      expect(response.dig("data", "organization", "works", "published")).to eq(
        [{ "count" => 6, "id" => "2011", "title" => "2011" }],
      )
      expect(
        response.dig("data", "organization", "works", "resourceTypes"),
      ).to eq([{ "count" => 6, "title" => "Dataset" }])
      expect(
        response.dig("data", "organization", "works", "nodes").length,
      ).to eq(6)

      works = response.dig("data", "organization", "works", "nodes")
      expect(works.any? { |w| w.dig("doi") == creator_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == contributor_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == funder_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == member_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == related_through_dmp_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == publisher_doi.doi.downcase }).to be true
      expect(works.any? { |w| w.dig("doi") == unrelated_doi.doi.downcase }).to be false
    end
  end

  describe "find organization by grid_id", elasticsearch: true, vcr: true do
    let!(:doi) do
      create(
        :doi,
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
            "affiliation": [
              {
                "name": "University of Cambridge",
                "affiliationIdentifier": "https://ror.org/013meh722",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
          },
        ],
      )
    end
    let!(:funder_doi) do
      create(
        :doi,
        aasm_state: "findable",
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100000735",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "University of Cambridge",
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
        organization(gridId: \"grid.5335.0\") {
          id
          name
          alternateName
          wikipediaUrl
          twitter
          inceptionYear
          country {
            id
            name
          }
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )
      expect(response.dig("data", "organization", "twitter")).to eq(
        "Cambridge_Uni",
      )
      expect(response.dig("data", "organization", "inceptionYear")).to eq(1_209)
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => 52.205277777778,
        "pointLongitude" => 0.11722222222222,
      )
      expect(response.dig("data", "organization", "citationCount")).to eq(0)
      expect(response.dig("data", "organization", "identifiers").count).to eq(
        53,
      )
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "10.13039/501100000735", "identifierType" => "fundref",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(response.dig("data", "organization", "works", "totalCount")).to eq(
        2,
      )
      expect(response.dig("data", "organization", "works", "published")).to eq(
        [{ "count" => 2, "id" => "2011", "title" => "2011" }],
      )
      expect(
        response.dig("data", "organization", "works", "resourceTypes"),
      ).to eq([{ "count" => 2, "title" => "Dataset" }])
      expect(
        response.dig("data", "organization", "works", "nodes").length,
      ).to eq(2)

      work = response.dig("data", "organization", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
    end
  end

  describe "find organization by crossref_funder_id",
           elasticsearch: true, vcr: true do
    let!(:doi) do
      create(
        :doi,
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
            "affiliation": [
              {
                "name": "University of Cambridge",
                "affiliationIdentifier": "https://ror.org/013meh722",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
          },
        ],
      )
    end
    let!(:funder_doi) do
      create(
        :doi,
        aasm_state: "findable",
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100000735",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "University of Cambridge",
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
        organization(crossrefFunderId: \"10.13039/501100000735\") {
          id
          name
          alternateName
          wikipediaUrl
          twitter
          inceptionYear
          country {
            id
            name
          }
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )
      expect(response.dig("data", "organization", "twitter")).to eq(
        "Cambridge_Uni",
      )
      expect(response.dig("data", "organization", "inceptionYear")).to eq(1_209)
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => 52.205277777778,
        "pointLongitude" => 0.11722222222222,
      )
      expect(response.dig("data", "organization", "citationCount")).to eq(0)
      expect(response.dig("data", "organization", "identifiers").count).to eq(
        53,
      )
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "10.13039/501100000735", "identifierType" => "fundref",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(response.dig("data", "organization", "works", "totalCount")).to eq(
        2,
      )
      expect(response.dig("data", "organization", "works", "published")).to eq(
        [{ "count" => 2, "id" => "2011", "title" => "2011" }],
      )
      expect(
        response.dig("data", "organization", "works", "resourceTypes"),
      ).to eq([{ "count" => 2, "title" => "Dataset" }])
      expect(
        response.dig("data", "organization", "works", "nodes").length,
      ).to eq(2)

      work = response.dig("data", "organization", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
    end
  end

  describe "find organization no wikidata", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organization(id: \"https://ror.org/02q0ygf45\") {
          id
          name
          alternateName
          wikipediaUrl
          twitter
          geolocation {
            pointLongitude
            pointLatitude
          }
          identifiers {
            identifier
            identifierType
          }
        }
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/02q0ygf45",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "OBS Medical (United Kingdom)",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Oxford BioSignals"],
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to be_nil
      expect(response.dig("data", "organization", "twitter")).to be_nil
      expect(response.dig("data", "organization", "inception_year")).to be_nil
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => nil, "pointLongitude" => nil,
      )
      expect(response.dig("data", "organization", "identifiers").count).to eq(2)
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "grid.487335.e", "identifierType" => "grid",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000403987680", "identifierType" => "isni",
      )
    end
  end

  describe "find organization with people", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organization(id: \"https://ror.org/013meh722\") {
          id
          name
          alternateName
          wikipediaUrl
          twitter
          inceptionYear
          country {
            id
            name
          }
          geolocation {
            pointLongitude
            pointLatitude
          }
          identifiers {
            identifier
            identifierType
          }
          people {
            totalCount
            nodes {
              id
              name
              givenName
              familyName
              alternateName
            }
          }
        }
      }"
    end

    xit "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(response.dig("data", "organization", "country")).to eq(
        "id" => "GB", "name" => "United Kingdom",
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )
      expect(response.dig("data", "organization", "twitter")).to eq(
        "Cambridge_Uni",
      )
      expect(response.dig("data", "organization", "inceptionYear")).to eq(1_209)
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => 52.205277777778,
        "pointLongitude" => 0.11722222222222,
      )
      expect(response.dig("data", "organization", "identifiers").count).to eq(
        38,
      )
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "10.13039/501100000735", "identifierType" => "fundref",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(
        response.dig("data", "organization", "people", "totalCount"),
      ).to eq(14_181)
      expect(
        response.dig("data", "organization", "people", "nodes").length,
      ).to eq(25)

      person = response.dig("data", "organization", "people", "nodes", 0)
      expect(person.dig("name")).to eq("Michael Edwards")
    end
  end

  describe "find organization with people query",
           elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organization(id: \"https://ror.org/013meh722\") {
          id
          name
          alternateName
          wikipediaUrl
          twitter
          inceptionYear
          country {
            id
            name
          }
          geolocation {
            pointLongitude
            pointLatitude
          }
          identifiers {
            identifier
            identifierType
          }
          people(query: \"oxford\") {
            totalCount
            nodes {
              id
              name
              givenName
              familyName
              alternateName
            }
          }
        }
      }"
    end

    xit "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organization", "id")).to eq(
        "https://ror.org/013meh722",
      )
      expect(response.dig("data", "organization", "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "organization", "alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(response.dig("data", "organization", "wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )
      expect(response.dig("data", "organization", "twitter")).to eq(
        "Cambridge_Uni",
      )
      expect(response.dig("data", "organization", "inceptionYear")).to eq(1_209)
      expect(response.dig("data", "organization", "geolocation")).to eq(
        "pointLatitude" => 52.205277777778,
        "pointLongitude" => 0.11722222222222,
      )
      expect(response.dig("data", "organization", "identifiers").count).to eq(
        38,
      )
      expect(response.dig("data", "organization", "identifiers").first).to eq(
        "identifier" => "10.13039/501100000735", "identifierType" => "fundref",
      )
      expect(response.dig("data", "organization", "identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(
        response.dig("data", "organization", "people", "totalCount"),
      ).to eq(1_988)
      expect(
        response.dig("data", "organization", "people", "nodes").length,
      ).to eq(25)

      person = response.dig("data", "organization", "people", "nodes", 0)
      expect(person.dig("name")).to eq("Christopher Haley")
    end
  end

  describe "find organization not found", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organization(id: \"https://ror.org/xxxx\") {
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq(
        [
          {
            "locations" => [{ "column" => 9, "line" => 2 }],
            "message" => "Record not found",
            "path" => %w[organization],
          },
        ],
      )
    end
  end

  describe "query all organizations", vcr: true do
    let(:query) do
      "query {
        organizations {
          totalCount
          years {
            id
            title
            count
          }
        }
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organizations", "totalCount")).to eq(114_882)
      expect(response.dig("data", "organizations", "years").first).to eq(
        "count" => 80_248, "id" => "2017", "title" => "2017",
      )
      expect(response.dig("data", "organizations", "years").last).to eq(
        "count" => 17063, "id" => "2021", "title" => "2021",
      )
    end
  end

  describe "query organizations", elasticsearch: true, vcr: true do
    let!(:dois) { create_list(:doi, 3) }
    let!(:doi) do
      create(
        :doi,
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
            "affiliation": [
              {
                "name": "University of Cambridge",
                "affiliationIdentifier": "https://ror.org/013meh722",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
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
        organizations(query: \"Cambridge University\", after: \"MQ\") {
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
            country {
              id
              name
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json
      expect(response.dig("data", "organizations", "totalCount")).to eq(12_418)
      expect(
        response.dig("data", "organizations", "pageInfo", "endCursor"),
      ).to eq("Mg")
      expect(
        response.dig("data", "organizations", "pageInfo", "hasNextPage"),
      ).to be true

      expect(response.dig("data", "organizations", "types").length).to eq(9)
      expect(response.dig("data", "organizations", "types").first).to eq(
        "count" => 10_993, "id" => "education", "title" => "Education",
      )
      expect(response.dig("data", "organizations", "countries").length).to eq(
        10,
      )
      expect(response.dig("data", "organizations", "countries").first).to eq(
        "count" => 1_880, "id" => "us", "title" => "United States of America",
      )
      expect(response.dig("data", "organizations", "nodes").length).to eq(20)
      organization = response.dig("data", "organizations", "nodes", 0)

      expect(organization.fetch("id")).to eq("https://ror.org/013meh722")
      expect(organization.fetch("name")).to eq("University of Cambridge")
      expect(organization.fetch("types")).to eq(%w[Education Funder])
      expect(organization.fetch("country")).to eq(
        "id" => "GB", "name" => "United Kingdom",
      )
      expect(organization.fetch("alternateName")).to eq(
        ["Cambridge University"],
      )
      expect(organization.fetch("url")).to eq(%w[https://www.cam.ac.uk])
      expect(organization.fetch("wikipediaUrl")).to eq(
        "http://en.wikipedia.org/wiki/University_of_Cambridge",
      )

      expect(organization.fetch("identifiers").length).to eq(53)
      expect(organization.fetch("identifiers").last).to eq(
        "identifier" => "0000000121885934", "identifierType" => "isni",
      )

      expect(organization.dig("works", "totalCount")).to eq(1)
      expect(organization.dig("works", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
    end
  end

  describe "query organizations with umlaut", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organizations(query: \"münster\") {
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
            country {
              id
              name
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organizations", "totalCount")).to eq(13)
      expect(response.dig("data", "organizations", "types").length).to eq(8)
      expect(response.dig("data", "organizations", "types").first).to eq(
        "count" => 4, "id" => "education", "title" => "Education",
      )
      expect(response.dig("data", "organizations", "countries").length).to eq(3)
      expect(response.dig("data", "organizations", "countries").first).to eq(
        "count" => 11, "id" => "de", "title" => "Germany",
      )
      expect(response.dig("data", "organizations", "nodes").length).to eq(13)
      organization = response.dig("data", "organizations", "nodes", 0)

      expect(organization.fetch("id")).to eq("https://ror.org/042a1e381")
      expect(organization.fetch("name")).to eq("Clemenshospital Münster")
      expect(organization.fetch("types")).to eq(%w[Healthcare])
      expect(organization.fetch("country")).to eq(
        "id" => "DE", "name" => "Germany",
      )
      expect(organization.fetch("alternateName")).to eq(%w[])
      expect(organization.fetch("url")).to eq(
        %w[https://www.clemenshospital.de/ch],
      )
      expect(organization.fetch("wikipediaUrl")).to be_nil

      expect(organization.fetch("identifiers").length).to eq(2)
      expect(organization.fetch("identifiers").last).to eq(
        "identifier" => "0000000405598961", "identifierType" => "isni",
      )
    end
  end

  describe "query organizations by type", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        organizations(types: \"government\", country: \"de\", after: \"MQ\") {
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
            country {
              id
              name
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
      }"
    end

    it "returns organization information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "organizations", "totalCount")).to eq(263)
      expect(
        response.dig("data", "organizations", "pageInfo", "endCursor"),
      ).to eq("Mg")
      expect(
        response.dig("data", "organizations", "pageInfo", "hasNextPage"),
      ).to be true

      expect(response.dig("data", "organizations", "types").length).to eq(3)
      expect(response.dig("data", "organizations", "types").first).to eq(
        "count" => 263, "id" => "government", "title" => "Government",
      )
      expect(response.dig("data", "organizations", "countries").length).to eq(1)
      expect(response.dig("data", "organizations", "countries").first).to eq(
        "count" => 263, "id" => "de", "title" => "Germany",
      )
      expect(response.dig("data", "organizations", "nodes").length).to eq(20)
      organization = response.dig("data", "organizations", "nodes", 0)
      expect(organization.fetch("id")).to eq("https://ror.org/007s7nj58")
      expect(organization.fetch("name")).to eq(
        "State Government of North Rhine Westphalia",
      )
      expect(organization.fetch("types")).to eq(%w[Government])
      expect(organization.fetch("country")).to eq(
        "id" => "DE", "name" => "Germany",
      )
      expect(organization.fetch("alternateName")).to eq(%w[])
      expect(organization.fetch("identifiers").length).to eq(2)
      expect(organization.fetch("identifiers").first).to eq(
        "identifier" => "Q1761666", "identifierType" => "wikidata",
      )
      expect(organization.dig("works", "totalCount")).to eq(0)
    end
  end
end
