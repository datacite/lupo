# frozen_string_literal: true

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
    it { is_expected.to have_field(:employment).of_type("[Employment!]") }
    it { is_expected.to have_field(:identifiers).of_type("[Identifier!]") }
    it { is_expected.to have_field(:country).of_type("Country") }
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

  describe "find person", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
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
      Client.import
      Event.import
      Doi.import
      sleep 3
    end

    let(:query) do
      "query {
        person(id: \"https://orcid.org/0000-0003-3484-6875\") {
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
          employment {
            organizationId
            organizationName
            roleTitle
            startDate
            endDate
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
      }"
    end

    xit "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq(
        "https://orcid.org/0000-0003-3484-6875",
      )
      expect(response.dig("data", "person", "name")).to eq("K. J. Garza")
      expect(response.dig("data", "person", "givenName")).to eq("Kristian")
      expect(response.dig("data", "person", "familyName")).to eq("Garza")
      expect(response.dig("data", "person", "alternateName")).to eq(
        ["Kristian Javier Garza Gutierrez"],
      )
      expect(response.dig("data", "person", "description")).to be_nil
      expect(response.dig("data", "person", "links")).to eq(
        [
          {
            "name" => "Mendeley profile",
            "url" => "https://www.mendeley.com/profiles/kristian-g/",
          },
          { "name" => "github", "url" => "https://github.com/kjgarza" },
        ],
      )
      expect(response.dig("data", "person", "identifiers")).to eq(
        [
          {
            "identifier" => "kjgarza",
            "identifierType" => "GitHub",
            "identifierUrl" => "https://github.com/kjgarza",
          },
        ],
      )
      expect(response.dig("data", "person", "country")).to eq(
        "id" => "DE", "name" => "Germany",
      )
      expect(response.dig("data", "person", "employment")).to eq(
        [
          {
            "endDate" => nil,
            "organizationId" => nil,
            "organizationName" => "DataCite",
            "roleTitle" => "Application Developer",
            "startDate" => "2016-08-01T00:00:00Z",
          },
        ],
      )
      expect(response.dig("data", "person", "citationCount")).to eq(2)
      expect(response.dig("data", "person", "viewCount")).to eq(0)
      expect(response.dig("data", "person", "downloadCount")).to eq(0)
      expect(response.dig("data", "person", "works", "totalCount")).to eq(1)
      expect(response.dig("data", "person", "works", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "person", "works", "resourceTypes")).to eq(
        [{ "count" => 1, "id" => "dataset", "title" => "Dataset" }],
      )
      expect(response.dig("data", "person", "works", "nodes").length).to eq(1)

      work = response.dig("data", "person", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
      expect(work.dig("citationCount")).to eq(2)
    end
  end

  describe "find person with employment", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        person(id: \"https://orcid.org/0000-0003-1419-2405\") {
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
          employment {
            organizationId
            organizationName
            roleTitle
            startDate
            endDate
          }
        }
      }"
    end

    xit "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq(
        "https://orcid.org/0000-0003-1419-2405",
      )
      expect(response.dig("data", "person", "name")).to eq("Martin Fenner")
      expect(response.dig("data", "person", "givenName")).to eq("Martin")
      expect(response.dig("data", "person", "familyName")).to eq("Fenner")
      expect(response.dig("data", "person", "alternateName")).to eq(
        ["Martin Hellmut Fenner"],
      )
      expect(response.dig("data", "person", "description")).to eq(
        "Martin Fenner is the DataCite Technical Director since 2015. From 2012 to 2015 he was the technical lead for the PLOS Article-Level Metrics project. Martin has a medical degree from the Free University of Berlin and is a Board-certified medical oncologist.",
      )
      expect(response.dig("data", "person", "links")).to eq(
        [{ "name" => "Twitter", "url" => "http://twitter.com/mfenner" }],
      )
      expect(response.dig("data", "person", "identifiers")).to eq(
        [
          {
            "identifier" => "7006600825",
            "identifierType" => "Scopus Author ID",
            "identifierUrl" =>
              "http://www.scopus.com/inward/authorDetails.url?authorID=7006600825&partnerID=MN8TOARS",
          },
          {
            "identifier" => "000000035060549X",
            "identifierType" => "ISNI",
            "identifierUrl" => "http://isni.org/000000035060549X",
          },
          {
            "identifier" => "mfenner",
            "identifierType" => "GitHub",
            "identifierUrl" => "https://github.com/mfenner",
          },
        ],
      )
      expect(response.dig("data", "person", "country")).to eq(
        "id" => "DE", "name" => "Germany",
      )
      expect(response.dig("data", "person", "employment")).to eq(
        [
          {
            "organizationId" => "https://grid.ac/institutes/grid.475826.a",
            "organizationName" => "DataCite",
            "roleTitle" => "Technical Director",
            "startDate" => "2015-08-01T00:00:00Z",
            "endDate" => nil,
          },
          {
            "organizationId" => "https://grid.ac/institutes/grid.10423.34",
            "organizationName" => "Hannover Medical School",
            "roleTitle" => "Clinical Fellow in Hematology and Oncology",
            "startDate" => "2005-11-01T00:00:00Z",
            "endDate" => "2017-05-01T00:00:00Z",
          },
          {
            "organizationId" => nil,
            "organizationName" => "Public Library of Science",
            "roleTitle" =>
              "Technical lead article-level metrics project (contractor)",
            "startDate" => "2012-04-01T00:00:00Z",
            "endDate" => "2015-07-01T00:00:00Z",
          },
          {
            "organizationId" => nil,
            "organizationName" => "Charité Universitätsmedizin Berlin",
            "roleTitle" => "Resident in Internal Medicine",
            "startDate" => "1998-09-01T00:00:00Z",
            "endDate" => "2005-10-01T00:00:00Z",
          },
        ],
      )
    end
  end

  describe "find person not found", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        person(id: \"https://orcid.org/xxxx\") {
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
      }"
    end

    xit "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq(
        [
          {
            "locations" => [{ "column" => 9, "line" => 2 }],
            "message" => "Record not found",
            "path" => %w[person],
          },
        ],
      )
    end
  end

  describe "find person account locked", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        person(id: \"https://orcid.org/0000-0003-1315-5960\") {
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
      }"
    end

    xit "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq(
        [
          {
            "locations" => [{ "column" => 9, "line" => 2 }],
            "message" =>
              "409 Conflict: The ORCID record is locked and cannot be edited. ORCID https://orcid.org/0000-0003-1315-5960",
            "path" => %w[person],
          },
        ],
      )
    end
  end

  describe "query all people", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        people {
          totalCount
          years {
            id
            title
            count
          }
        }
      }"
    end

    xit "returns people information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "people", "totalCount")).to eq(9_688_620)
      expect(response.dig("data", "people", "years").first).to eq(
        "count" => 44_270, "id" => "2012", "title" => "2012",
      )
      expect(response.dig("data", "people", "years").last).to eq(
        "count" => 1_767_011, "id" => "2021", "title" => "2021",
      )
    end
  end

  describe "query people", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        people(query: \"Fenner\", first: 50, after: \"NA\") {
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
      }"
    end

    xit "returns people information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "people", "totalCount")).to eq(262)
      expect(response.dig("data", "people", "pageInfo", "endCursor")).to eq(
        "NQ",
      )
      # expect(response.dig("data", "people", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "people", "nodes").length).to eq(50)

      person = response.dig("data", "people", "nodes", 0)
      expect(person.fetch("id")).to eq("https://orcid.org/0000-0003-2494-0518")
      expect(person.fetch("name")).to eq("Baihua Fu")
      expect(person.fetch("givenName")).to eq("Baihua")
      expect(person.fetch("familyName")).to eq("Fu")
      expect(person.fetch("alternateName")).to eq([])
    end
  end

  describe "query people with error", elasticsearch: true, vcr: true do
    let(:query) do
      "query {
        people(query: \"container.identifier:2658-719X\") {
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
      }"
    end

    xit "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors", 0, "message")).to start_with(
        "org.apache.solr.client.solrj.impl.HttpSolrClient.RemoteSolrException",
      )
    end
  end

  # describe "update user profile", elasticsearch: true, vcr: true do
  #   let(:query) do
  #     "mutation {
  #       updateUserProfile(uid: \"0000-0001-6528-2027\", name: \"Martin H. Fenner\") {
  #         user {
  #           uid
  #           name
  #         }
  #       }
  #     }"
  #   end

  #   it "returns user" do
  #     current_user =
  #       User.new(
  #         User.generate_token(
  #           uid: "0000-0001-6528-2027",
  #           name: "Martin Fenner",
  #           has_orcid_token: true,
  #         ),
  #       )
  #     response =
  #       LupoSchema.execute(query, context: { current_user: current_user }).
  #         as_json

  #     expect(response.dig("data", "updateUserProfile", "user", "uid")).to eq(
  #       "d140d44e-af70-43ec-a90b-49878a954487",
  #     )
  #     expect(response.dig("data", "updateUserProfile", "user", "name")).to eq(
  #       "orcid_update",
  #     )
  #   end
  # end

  describe "query people with absolute orcid uri", elasticsearch: true, vcr: true do
    let(:query) do
      "query asdfsadfa {
        people(first: 25, query: \"https://orcid.org/0000-0001-5727-2427\", after: null) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
            __typename
          }
          nodes {
            id
            name
            givenName
            familyName
            alternateName
            __typename
          }
          __typename
        }
      }"
    end

    it "returns success response" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "errors")).to(eq(nil))
    end
  end

  describe "query people with nil query should not throw NilClass error", elasticsearch: true, vcr: true do
    let(:query) do
      "query asdfsadfa {
        people(first: 25, query: null, after: null) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
            __typename
          }
          nodes {
            id
            name
            givenName
            familyName
            alternateName
            __typename
          }
          __typename
        }
      }"
    end

    it "returns success response" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "errors")).to(eq(nil))
    end
  end
end
