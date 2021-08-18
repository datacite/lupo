# frozen_string_literal: true

require "rails_helper"

describe WorkType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "find work", elasticsearch: true do
    let!(:work) do
      create(
        :doi,
        aasm_state: "findable",
        container: {
          "type" => "Journal",
          "issue" => "9",
          "title" => "Inorganica Chimica Acta",
          "volume" => "362",
          "lastPage" => "3180",
          "firstPage" => "3172",
          "identifier" => "0020-1693",
          "identifierType" => "ISSN",
        },
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          id
          repository {
            id
            type
            name
          }
          member {
            id
            type
            name
          }
          container {
            identifier
            identifierType
            title
          }
          bibtex
          xml
          schemaOrg
        }
      }"
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq(
        "https://handle.stage.datacite.org/#{work.doi.downcase}",
      )
      expect(response.dig("data", "work", "container")).to eq(
        "identifier" => "0020-1693",
        "identifierType" => "ISSN",
        "title" => "Inorganica Chimica Acta",
      )
      expect(response.dig("data", "work", "repository", "id")).to eq(
        work.client_id,
      )
      expect(response.dig("data", "work", "repository", "name")).to eq(
        work.client.name,
      )
      expect(response.dig("data", "work", "member", "id")).to eq(
        work.provider_id,
      )
      expect(response.dig("data", "work", "member", "name")).to eq(
        work.provider.name,
      )
      expect(response.dig("data", "work", "id")).to eq(
        "https://handle.stage.datacite.org/#{work.doi.downcase}",
      )

      bibtex =
        BibTeX.parse(response.dig("data", "work", "bibtex")).to_a(quotes: "").
          first
      expect(bibtex[:bibtex_type].to_s).to eq("misc")
      expect(bibtex[:bibtex_key]).to eq("https://doi.org/#{work.doi.downcase}")
      expect(bibtex[:author]).to eq(
        "Ollomo, Benjamin and Durand, Patrick and Prugnolle, Franck and Douzery, Emmanuel J. P. and Arnathau, Céline and Nkoghe, Dieudonné and Leroy, Eric and Renaud, François",
      )
      expect(bibtex[:title]).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
      expect(bibtex[:year]).to eq("2011")

      schema_org = JSON.parse(response.dig("data", "work", "schemaOrg"))
      expect(schema_org["@id"]).to eq("https://doi.org/#{work.doi.downcase}")
      expect(schema_org["name"]).to eq(
        "Data from: A new malaria agent in African hominids.",
      )

      doc =
        Nokogiri.XML(
          response.dig("data", "work", "xml"),
          nil,
          "UTF-8",
          &:noblanks
        )
      expect(doc.at_css("identifier").content).to eq(work.doi)
      expect(doc.at_css("titles").content).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
    end
  end

  describe "find work with claims", elasticsearch: true, vcr: true do
    let!(:work) do
      create(:doi, doi: "10.17863/cam.536", aasm_state: "findable")
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          id
          claims {
            sourceId
            state
            claimed
            errorMessages {
              status
              title
            }
          }
        }
      }"
    end

    it "returns work" do
      current_user =
        User.new(User.generate_token(uid: "0000-0001-5663-772X", aud: "stage"))
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "work", "id")).to eq(
        "https://handle.stage.datacite.org/#{work.doi.downcase}",
      )
      expect(response.dig("data", "work", "claims")).to eq(
        [
          {
            "claimed" => "2017-10-16T11:15:01Z",
            "errorMessages" => [],
            "sourceId" => "orcid_update",
            "state" => "done",
          },
        ],
      )
    end
  end

  describe "find work with claims and errors", elasticsearch: true, vcr: true do
    let!(:work) do
      create(:doi, doi: "10.70048/sc61-b496", aasm_state: "findable")
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          id
          claims {
            sourceId
            state
            claimed
            errorMessages {
              status
              title
            }
          }
        }
      }"
    end

    it "returns work" do
      current_user =
        User.new(User.generate_token(uid: "0000-0002-7352-517X", aud: "stage"))
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "work", "id")).to eq(
        "https://handle.stage.datacite.org/#{work.doi.downcase}",
      )
      expect(response.dig("data", "work", "claims")).to eq(
        [
          {
            "claimed" => nil,
            "errorMessages" => [{ "status" => nil, "title" => "Missing data" }],
            "sourceId" => "orcid_update",
            "state" => "failed",
          },
        ],
      )
    end
  end

  describe "find work crossref", elasticsearch: true, vcr: true do
    let!(:work) do
      create(
        :doi,
        doi: "10.1038/nature12373",
        agency: "crossref",
        aasm_state: "findable",
        titles: [{ "title" => "Nanometre-scale thermometry in a living cell" }],
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          id
          titles {
            title
          }
          url
          contentUrl
        }
      }"
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq(
        "https://handle.stage.datacite.org/#{work.doi.downcase}",
      )
      expect(response.dig("data", "work", "titles")).to eq(
        [{ "title" => "Nanometre-scale thermometry in a living cell" }],
      )
      expect(response.dig("data", "work", "url")).to eq(work.url)
      expect(response.dig("data", "work", "contentUrl")).to eq(
        "https://dash.harvard.edu/bitstream/1/12285462/1/Nanometer-Scale%20Thermometry.pdf",
      )
    end
  end

  describe "find work not found", elasticsearch: true do
    let(:query) do
      "query {
        work(id: \"https://doi.org/10.14454/xxx\") {
          id
          repository {
            id
            type
            name
          }
          member {
            id
            type
            name
          }
          container {
            identifier
            identifierType
            title
          }
          bibtex
          xml
          schemaOrg
        }
      }"
    end

    it "returns error" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq(
        [
          {
            "locations" => [{ "column" => 9, "line" => 2 }],
            "message" => "undefined method `[]' for nil:NilClass",
            "path" => %w[work],
          },
        ],
      )
    end
  end

  describe "query works", elasticsearch: true, vcr: true do
    let(:query) do
      "query($first: Int, $cursor: String) {
        works(first: $first, after: $cursor) {
          totalCount
          totalCountFromCrossref
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            doi
            creators{
              type
            }
          }
        }
        associated: works(hasAffiliation: true, hasFunder: true, hasOrganization: true, hasMember: true) {
          totalCount
          published {
            id
            title
            count
          }
        }
        contributed: works(hasOrganization: true) {
          totalCount
          published {
            id
            title
            count
          }
        }
        affiliated: works(hasAffiliation: true) {
          totalCount
          published {
            id
            title
            count
          }
        }
        funded: works(hasFunder: true) {
          totalCount
          published {
            id
            title
            count
          }
        }
        hosted: works(hasMember: true) {
          totalCount
          published {
            id
            title
            count
          }
        }
      }"
    end

    let(:provider) do
      create(:provider, symbol: "LPSW", ror_id: "https://ror.org/013meh722")
    end
    let(:provider_without_ror) { create(:provider, ror_id: nil) }
    let(:client) { create(:client, provider: provider) }
    let(:client_without_ror) { create(:client, provider: provider_without_ror) }
    let!(:works) do
      create_list(
        :doi,
        10,
        aasm_state: "findable",
        client: client_without_ror,
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
    let!(:doi) do
      create(
        :doi,
        aasm_state: "findable",
        client: client_without_ror,
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
          {
            "name" => "University of Cambridge",
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
    let!(:organization_doi) do
      create(
        :doi,
        aasm_state: "findable",
        client: client_without_ror,
        creators: [
          {
            "name" => "Department of Psychoceramics, University of Cambridge",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh722",
                "nameIdentifierScheme" => "ROR",
                "schemeUri" => "https://ror.org",
              },
            ],
            "nameType" => "Organizational",
          },
        ],
      )
    end
    let!(:funder_doi) do
      create(
        :doi,
        aasm_state: "findable",
        client: client_without_ror,
        funding_references: [
          {
            "funderIdentifier" => "https://doi.org/10.13039/501100000735",
            "funderIdentifierType" => "Crossref Funder ID",
            "funderName" => "University of Cambridge",
          },
        ],
      )
    end
    let!(:member_doi) { create(:doi, aasm_state: "findable", client: client) }

    before do
      Doi.import
      sleep 2
      @works = Doi.gql_query(nil, page: { cursor: [], size: 15 }).results.to_a
    end

    it "returns all works" do
      response =
        LupoSchema.execute(query, variables: { first: 4, cursor: nil }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(14)
      expect(response.dig("data", "works", "totalCountFromCrossref")).to eq(
        116_990_655,
      )
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "works", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@works[3].uid)
      expect(
        response.dig("data", "works", "pageInfo", "hasNextPage"),
      ).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(
        @works[0].identifier,
      )
      expect(
        response.dig("data", "works", "nodes", 0, "creators", 1, "type"),
      ).to be nil
      end_cursor = response.dig("data", "works", "pageInfo", "endCursor")

      response =
        LupoSchema.execute(query, variables: { first: 4, cursor: end_cursor }).
          as_json

      expect(response.dig("data", "works", "totalCount")).to eq(14)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "works", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@works[7].uid)
      expect(
        response.dig("data", "works", "pageInfo", "hasNextPage"),
      ).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(
        @works[4].identifier,
      )
      end_cursor = response.dig("data", "works", "pageInfo", "endCursor")

      response =
        LupoSchema.execute(query, variables: { first: 4, cursor: end_cursor }).
          as_json

      expect(response.dig("data", "works", "totalCount")).to eq(14)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "works", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@works[11].uid)
      expect(
        response.dig("data", "works", "pageInfo", "hasNextPage"),
      ).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(
        @works[8].identifier,
      )
      expect(response.dig("data", "associated", "totalCount")).to eq(4)
      expect(response.dig("data", "associated", "published")).to eq(
        [{ "count" => 4, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "contributed", "totalCount")).to eq(1)
      expect(response.dig("data", "contributed", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "affiliated", "totalCount")).to eq(3)
      expect(response.dig("data", "affiliated", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "funded", "totalCount")).to eq(1)
      expect(response.dig("data", "funded", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "hosted", "totalCount")).to eq(1)
      expect(response.dig("data", "hosted", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
    end
  end

  describe "query works by registration agency",
           elasticsearch: true, vcr: true do
    let(:query) do
      "query($first: Int, $cursor: String, $registrationAgency: String) {
        works(first: $first, after: $cursor, registrationAgency: $registrationAgency) {
          totalCount
          totalCountFromCrossref
          pageInfo {
            endCursor
            hasNextPage
          }
          registrationAgencies {
            id
            title
            count
          }
          languages {
            id
            title
            count
          }
          nodes {
            id
            doi
            registered
            language {
              id
              name
            }
            registrationAgency {
              id
              name
            }
          }
        }
      }"
    end

    let!(:works) do
      create_list(
        :doi,
        10,
        aasm_state: "findable", language: "nl", agency: "datacite",
      )
    end
    let!(:work) do
      create(:doi, aasm_state: "findable", language: "de", agency: "crossref")
    end

    before do
      Doi.import
      sleep 2
      @works = Doi.gql_query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response =
        LupoSchema.execute(
          query,
          variables: { first: 4, cursor: nil, registrationAgency: "datacite" },
        ).
          as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "totalCountFromCrossref")).to eq(
        116_990_655,
      )
      expect(response.dig("data", "works", "registrationAgencies")).to eq(
        [{ "count" => 10, "id" => "datacite", "title" => "DataCite" }],
      )
      expect(response.dig("data", "works", "languages")).to eq(
        [{ "count" => 10, "id" => "nl", "title" => "Dutch" }],
      )
      # expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(
        response.dig("data", "works", "pageInfo", "hasNextPage"),
      ).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(
        response.dig("data", "works", "nodes", 0, "registered"),
      ).to start_with(@works[0].registered[0..9])
      expect(response.dig("data", "works", "nodes", 0, "language")).to eq(
        "id" => "nl", "name" => "Dutch",
      )
      expect(
        response.dig("data", "works", "nodes", 0, "registrationAgency"),
      ).to eq("id" => "datacite", "name" => "DataCite")
    end
  end

  describe "query works by license", elasticsearch: true do
    let(:query) do
      "query($first: Int, $cursor: String, $license: String) {
        works(first: $first, after: $cursor, license: $license) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          licenses {
            id
            title
            count
          }
          nodes {
            id
            doi
            registered
            subjects {
              subject
              subjectScheme
            }
            rights {
              rights
              rightsUri
              rightsIdentifier
            }
          }
        }
      }"
    end

    let!(:works) do
      create_list(
        :doi,
        10,
        aasm_state: "findable",
        agency: "datacite",
        subjects: [{ "subject" => "Computer and information sciences" }],
      )
    end
    let!(:work) do
      create(:doi, aasm_state: "findable", agency: "crossref", rights_list: [])
    end

    before do
      Doi.import
      sleep 2
      @works = Doi.gql_query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response =
        LupoSchema.execute(
          query,
          variables: { first: 4, cursor: nil, license: "cc0-1.0" },
        ).
          as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "licenses")).to eq(
        [{ "count" => 10, "id" => "cc0-1.0", "title" => "CC0-1.0" }],
      )
      # expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(
        response.dig("data", "works", "pageInfo", "hasNextPage"),
      ).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(
        @works[0].identifier,
      )
      expect(
        response.dig("data", "works", "nodes", 0, "registered"),
      ).to start_with(@works[0].registered[0..9])
      expect(response.dig("data", "works", "nodes", 0, "subjects")).to eq(
        [
          {
            "subject" => "Computer and information sciences",
            "subjectScheme" => nil,
          },
          {
            "subject" => "FOS: Computer and information sciences",
            "subjectScheme" => "Fields of Science and Technology (FOS)",
          },
        ],
      )
      expect(response.dig("data", "works", "nodes", 0, "rights")).to eq(
        [
          {
            "rights" => "Creative Commons Zero v1.0 Universal",
            "rightsIdentifier" => "cc0-1.0",
            "rightsUri" =>
              "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
          },
        ],
      )
    end
  end

  describe "create claim", elasticsearch: true, vcr: true do
    let(:query) do
      "mutation {
        createClaim(doi: \"10.5438/4hr0-d640\", id: \"d140d44e-af70-43ec-a90b-49878a954487\", sourceId: \"orcid_update\") {
          claim {
            id
            state
            sourceId
            errorMessages {
              title
            }
          }
          errors {
            status
            source
            title
          }
        }
      }"
    end

    it "returns claim" do
      current_user =
        User.new(
          User.generate_token(
            uid: "0000-0001-6528-2027",
            name: "Martin Fenner",
            has_orcid_token: true,
          ),
        )
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "createClaim", "claim", "id")).to eq(
        "d140d44e-af70-43ec-a90b-49878a954487",
      )
      expect(response.dig("data", "createClaim", "claim", "sourceId")).to eq(
        "orcid_update",
      )
      expect(response.dig("data", "createClaim", "claim", "state")).to eq(
        "failed",
      )
      expect(
        response.dig("data", "createClaim", "claim", "errorMessages"),
      ).to eq([{ "title" => "Missing data" }])
      expect(response.dig("data", "createClaim", "errors")).to be_empty
    end
  end

  describe "delete claim", elasticsearch: true, vcr: true do
    let(:query) do
      "mutation {
        deleteClaim(id: \"d140d44e-af70-43ec-a90b-49878a954487\") {
          message
          errors {
            status
            title
          }
        }
      }"
    end

    it "returns success message" do
      current_user =
        User.new(
          User.generate_token(
            uid: "0000-0001-6528-2027", aud: "stage", has_orcid_token: true,
          ),
        )
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "deleteClaim", "message")).to eq(
        "Claim d140d44e-af70-43ec-a90b-49878a954487 deleted.",
      )
      expect(response.dig("data", "deleteClaim", "errors")).to be_blank
    end
  end

  describe "delete claim not found", elasticsearch: true, vcr: true do
    let(:query) do
      "mutation {
        deleteClaim(id: \"6dcaeca5-7e5a-449a-86b8-f2ae80db3fef\") {
          message
          errors {
            status
            title
          }
        }
      }"
    end

    it "returns error message" do
      current_user =
        User.new(
          User.generate_token(
            uid: "0000-0001-6528-2027", aud: "stage", has_orcid_token: true,
          ),
        )
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "deleteClaim", "message")).to eq(
        "Error deleting claim 6dcaeca5-7e5a-449a-86b8-f2ae80db3fef.",
      )
      expect(response.dig("data", "deleteClaim", "errors")).to eq(
        [{ "status" => 404, "title" => "Not found" }],
      )
    end
  end
end
