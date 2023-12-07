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
    let!(:repository) do
      create(:reference_repository, client_id: work.client.symbol)
    end

    before do
      Doi.import
      ReferenceRepository.import
      sleep 2
    end

    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          id
          repository {
            clientId
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
          publisher
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
      expect(response.dig("data", "work", "repository", "clientId")).to eq(
        work.client.uid,
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
      expect(response.dig("data", "work", "publisher")).to eq(
        "Dryad Digital Repository",
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
            clientId
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
            "message" => "Record not found",
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
            publisher
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
      expect(
        response.dig("data", "works", "nodes", 0, "publisher"),
      ).to eq("Dryad Digital Repository")
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
          repositories {
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
      expect(response.dig("data", "works", "repositories").first["title"]).to eq(
        "My data center"
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
            uid: "0000-0002-7352-517X",
            name: "Richard Hallett",
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
        deleteClaim(id: \"79b54ea5-7a38-4fd1-bc75-57708492d910\") {
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

    it "returns success message" do
      current_user =
        User.new(
          User.generate_token(
            uid: "0000-0002-7352-517X", aud: "stage", has_orcid_token: true,
          ),
        )
      response =
        LupoSchema.execute(query, context: { current_user: current_user }).
          as_json

      expect(response.dig("data", "deleteClaim", "claim", "id")).to eq(
        "79b54ea5-7a38-4fd1-bc75-57708492d910",
      )

      expect(response.dig("data", "deleteClaim", "errors")).to be_blank
    end
  end

  describe "delete claim not found", elasticsearch: true, vcr: true do
    let(:query) do
      "mutation {
        deleteClaim(id: \"6dcaeca5-7e5a-449a-86b8-f2ae80db3fef\") {
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

      expect(response.dig("data", "deleteClaim", "errors")).to eq(
        [{ "status" => 404, "title" => "Not found" }],
      )
    end
  end

  describe "find work with a creator or contributor with an affiliation property that's a hash", elasticsearch: true do
    let!(:work) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "name" => "Kristian Garza",
            "nameType" => "Personal",
            "affiliation" => {
              "name" => "Ruhr-University Bochum, Germany"
            }
          },
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
            "name" => "Cody Ross",
            "nameType" => "Personal",
          },
        ],
        contributors: [
          {
            "givenName" => "Cody",
            "familyName" => "Ross",
            "contributorType" => "Editor",
            "affiliation" => {
              "name" => "Ruhr-University Bochum, Germany"
            }
          },
          {
            "givenName" => "Kristian",
            "familyName" => "Garza",
            "contributorType" => "Editor",
            "affiliation" => [
              {
              "name" => "University of Cambridge",
              "affiliationIdentifier": "https://ror.org/013meh722",
              "affiliationIdentifierScheme": "ROR",
            }
          ]
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query_work) do
      "query {
        work(id: \"https://doi.org/#{
        work.doi
      }\") {
          creators {
            id
            name
            givenName
            familyName
            affiliation {
              id
              name
            }
          }
          contributors {
            id
            name
            givenName
            familyName
            affiliation {
              id
              name
            }
          }
        }
      }"
    end

    let(:query_works) do
      "query {
        works(ids: [\"#{
        work.doi
      }\"]) {
          nodes {
            creators {
              id
              name
              givenName
              familyName
              affiliation {
                id
                name
              }
            }
            contributors {
              id
              name
              givenName
              familyName
              affiliation {
                id
                name
              }
            }
          }
        }
      }"
    end

    it "returns work with a non-nil creators type" do
      response = LupoSchema.execute(query_work).as_json

      expect(response.dig("data", "work", "creators", 0, "affiliation", 0, "name")).to eq(
        "Ruhr-University Bochum, Germany",
      )
      expect(response.dig("data", "work", "creators", 1, "affiliation", 0, "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "work", "contributors", 0, "affiliation", 0, "name")).to eq(
        "Ruhr-University Bochum, Germany",
      )
    end

    it "returns works with non-nil creators types" do
      response = LupoSchema.execute(query_works).as_json

      expect(response.dig("data", "works", "nodes", 0, "creators", 0, "affiliation", 0, "name")).to eq(
        "Ruhr-University Bochum, Germany",
      )
      expect(response.dig("data", "works", "nodes", 0, "creators", 1, "affiliation", 0, "name")).to eq(
        "University of Cambridge",
      )
      expect(response.dig("data", "works", "nodes", 0, "contributors", 0, "affiliation", 0, "name")).to eq(
        "Ruhr-University Bochum, Germany",
      )
    end
  end

  describe "find work with a creator or contributor with a nameIdentifier property that's a hash", elasticsearch: true do
    let!(:work) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "name" => "Kristian Garza",
            "nameType" => "Personal",
            "nameIdentifiers" =>
              {
                "schemeUri": "https://orcid.org",
                "nameIdentifier": "https://orcid.org/0000-0002-7105-9881",
                "nameIdentifierScheme": "ORCID"
              }
          },
          {
            "name" => "Ross, Cody",
            "familyName" => "Ross",
            "givenName" => "Cody",
            "nameIdentifiers" =>
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            "nameType" => "Personal",
          },
        ],
        contributors: [
          {
            "givenName" => "Cody",
            "familyName" => "Ross",
            "contributorType" => "Editor",
            "nameIdentifiers" =>
              {
                "schemeUri": "https://orcid.org",
                "nameIdentifier": "https://orcid.org/0000-0002-7105-9881",
                "nameIdentifierScheme": "ORCID"
              }
          },
          {
            "givenName" => "Kristian",
            "familyName" => "Garza",
            "contributorType" => "Editor",
            "nameIdentifiers" =>
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query_works) do
      "query {
        works(ids: [\"#{
        work.doi
      }\"]) {
          authors {
            id
            title
            count
          }
          nodes {
            creators {
              id
              name
              givenName
              familyName
            }
            contributors {
              id
              name
              givenName
              familyName
              contributorType
            }
          }
        }
      }"
    end

    it "returns works with authors facet" do
      response = LupoSchema.execute(query_works).as_json

      expect(response).to_not have_key("errors")
      expect(response.dig("data", "works", "authors").length).to eq(2)
      expect(response.dig("data", "works", "authors", 0)).to eq(
        { "id" => "https://orcid.org/0000-0002-7105-9881",
          "title" => "Kristian Garza",
          "count" => 1 }
      )
    end

    it "returns work node with creators and contributors" do
      response = LupoSchema.execute(query_works).as_json

      expect(response).to_not have_key("errors")
      expect(response.dig("data", "works", "nodes", 0, "creators").length).to eq(2)
      expect(response.dig("data", "works", "nodes", 0, "creators")).to eq(
        [
          { "id" => "https://orcid.org/0000-0002-7105-9881",
          "name" => "Kristian Garza",
          "givenName" => nil,
          "familyName" => nil },
         { "id" => "https://orcid.org/0000-0003-3484-6875",
          "name" => "Ross, Cody",
          "givenName" => "Cody",
          "familyName" => "Ross" }
        ]
      )
      expect(response.dig("data", "works", "nodes", 0, "contributors").length).to eq(2)
      expect(response.dig("data", "works", "nodes", 0, "contributors")).to eq(
        [
          { "id" => "https://orcid.org/0000-0002-7105-9881",
          "name" => nil,
          "givenName" => "Cody",
          "familyName" => "Ross",
          "contributorType" => "Editor" },
          { "id" => "https://orcid.org/0000-0003-3484-6875",
            "name" => nil,
            "givenName" => "Kristian",
            "familyName" => "Garza",
            "contributorType" => "Editor" }
        ]
      )
    end
  end

  describe "get author aggregations when creators have multiple nameIdentifiers", elasticsearch: true do
    let!(:work_one) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "name" => "Garza, Kristian",
            "nameType" => "Personal",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
              {
                "nameIdentifier" => "http://id.loc.gov/authorities/names/n90722093",
                "nameIdentifierScheme" => "LCNAF",
                "schemeUri" => "http://id.loc.gov/authorities/names",
              },
            ],
          },
          {
            "familyName" => "Ross",
            "givenName" => "Cody",
            "name" => "Ross, Cody",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "http://id.loc.gov/authorities/names/no90016802",
                "nameIdentifierScheme" => "LCNAF",
                "schemeUri" => "http://id.loc.gov/authorities/names",
              },
              {
                "nameIdentifier" => "https://orcid.org/0000-0002-4684-9769",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          },
          {
            "name" => "Cody Ross",
            "nameType" => "Personal",
          },
        ],
      )
    end

    let!(:work_two) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "name" => "Garza, Kristian",
            "nameType" => "Personal",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "http://id.loc.gov/authorities/names/n90722093",
                "nameIdentifierScheme" => "LCNAF",
                "schemeUri" => "http://id.loc.gov/authorities/names",
              },
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          },
          {
            "familyName" => "Ross",
            "givenName" => "Cody",
            "name" => "Ross, Cody",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0002-4684-9769",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          },
          {
            "name" => "Cody Ross",
            "nameType" => "Personal",
          },
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

    before do
      Doi.import
      sleep 2
    end

    let(:query_works) do
      'query {
        works(query:"") {
          authors {
            count
            id
            title
          }
          nodes {
            creators {
              id
              name
              givenName
              familyName
              affiliation {
                id
                name
              }
            }
          }
        }
      }'
    end

    it "returns author aggregation that is an array of authors with ORCID nameIdentifiers" do
      response = LupoSchema.execute(query_works).as_json

      expect(response.dig("data", "works", "authors").count).to eq(2)

      expect(response.dig("data", "works", "authors")).to eq(
        [
          {
            "count" => 2,
            "id" => "https://orcid.org/0000-0002-4684-9769",
            "title" => "Ross, Cody"
          },
          {
            "count" => 2,
            "id" => "https://orcid.org/0000-0003-3484-6875",
            "title" => "Garza, Kristian"
          },
        ]
      )
    end
  end

  describe "query works with repository subjects" do
    before :all do
      SLEEP_TIME = 2
      WORK_COUNT = 10

      DataciteDoi.import(force: true)
      Client.import(force: true)
      Prefix.import(force: true)
      ClientPrefix.import(force: true)
      ReferenceRepository.import(force: true)
      Event.import(force: true)

      search_query = '
        fragment facetFields on Facet {
          id
          title
          count
        }
        query{
          works(query:"*"){
            totalCount
            fieldsOfScience { ...facetFields }
            fieldsOfScienceRepository { ...facetFields }
            fieldsOfScienceCombined{ ...facetFields }
          }
        }
      '

      create(:prefix)
      client = create(:client_with_fos)
      create_list(:doi, WORK_COUNT,
        aasm_state: "findable",
        client: client
      )
      Doi.import
      sleep SLEEP_TIME
      @facet_response = LupoSchema.execute(search_query).as_json
      Rails.logger.level = :fatal
      DataciteDoi.destroy_all
      ReferenceRepository.destroy_all
      Client.destroy_all
      Provider.destroy_all
      Prefix.destroy_all
      ClientPrefix.destroy_all
      ProviderPrefix.destroy_all
      Event.destroy_all
    end

    let (:fos_facet) do
      {
        "id" => "physical_sciences",
        "title" => "Physical sciences",
        "count" => WORK_COUNT
      }
    end

    it "has all dois in the search results" do
      response = @facet_response
      expect(response.dig("data", "works", "totalCount")).to eq(WORK_COUNT)
    end

    it "returns Field of Science Facets" do
      response = @facet_response
      expect(
        response.dig("data", "works", "fieldsOfScience")
      ).to match_array([])
    end

    it "returns Field of Science Facets from the repository" do
      response = @facet_response
      expect(
        response.dig("data", "works", "fieldsOfScienceRepository")
      ).to match_array([ fos_facet ])
    end

    it "returns combined Field of Science Facets" do
      response = @facet_response
      expect(
        response.dig("data", "works", "fieldsOfScienceCombined")
      ).to match_array([ fos_facet ])
    end
  end


  describe "get formatted citation", elasticsearch: true do
    let!(:work_one) do
      create(
        :doi,
        doi: "10.14454/X45ZNPCOA",
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query_works) do
      '
      query (
        $id: ID!
        $format: CitationFormat
        ){
          work(id:$id) {
            id
            formattedCitation(format: $format)
            publicationYear
          }
        }
      '
    end

    it "returns formatted citation in html" do
      response = LupoSchema.execute(
        query_works, variables: { id: work_one.doi }
      ).as_json
      expect(response.dig("data", "work", "formattedCitation")).to eq(
        "Ollomo, B., Durand, P., Prugnolle, F., Douzery, E. J. P., Arnathau, C., Nkoghe, D., Leroy, E., &amp; Renaud, F. (2011). <i>Data from: A new malaria agent in African hominids.</i> [Data set]. Dryad Digital Repository. <a href='https://doi.org/10.14454/X45ZNPCOA'>https://doi.org/10.14454/X45ZNPCOA</a>"
      )
    end

    it "returns formatted citation in plain text" do
      response = LupoSchema.execute(
        query_works,
        variables: { id: work_one.doi, format: "text" }
      ).as_json
      expect(response.dig("data", "work", "formattedCitation")).to eq(
        "Ollomo, B., Durand, P., Prugnolle, F., Douzery, E. J. P., Arnathau, C., Nkoghe, D., Leroy, E., & Renaud, F. (2011). Data from: A new malaria agent in African hominids. [Data set]. Dryad Digital Repository. https://doi.org/10.14454/X45ZNPCOA"
      )
    end

    it "returns error for unknown citation format" do
      response = LupoSchema.execute(
        query_works,
        variables: { id: work_one.doi, format: "unsupported" }
      ).as_json
      problem = response.dig("errors", 0, "extensions", "problems").first
      expect(problem.dig("explanation")).to eq(
        "Expected \"unsupported\" to be one of: html, text"
      )
    end
  end

  describe "query fields with __other__ and __missing__ data", elasticsearch: true do
    let(:query) do
      "query($first: Int, $cursor: String, $facetCount: Int) {
        works(first: $first, after: $cursor, facetCount: $facetCount) {
          totalCount
          resourceTypes {
            id
            title
            count
          }
          affiliations {
            id
            title
            count
          }
          licenses {
            id
            title
            count
          }
        }
      }"
    end

    let!(:works_5) do
      create_list(:doi, 5, aasm_state: "findable",
        types: { "resourceTypeGeneral" => "Text" },
        creators: [{
          affiliation: [{
            "name": "5",
            "affiliationIdentifier": "https://ror.org/5",
            "affiliationIdentifierScheme": "ROR",
          }],
        }],
        rights_list: [{ "rightsIdentifier" => "cc-by-1.0" }]
      )
    end
    let!(:works_4) do
      create_list(:doi, 4, aasm_state: "findable",
        types: { "resourceTypeGeneral" => "JournalArticle" },
        creators: [{
          affiliation: [{
            "name": "4",
            "affiliationIdentifier": "https://ror.org/4",
            "affiliationIdentifierScheme": "ROR",
          }],
        }],
        rights_list: [{ "rightsIdentifier" => "cc-by-2.0" }]
      )
    end
    let!(:works_3) do
      create_list(:doi, 3, aasm_state: "findable",
        types: { "resourceTypeGeneral" => "Image" },
        creators: [{
          affiliation: [{
            "name": "3",
            "affiliationIdentifier": "https://ror.org/3",
            "affiliationIdentifierScheme": "ROR",
          }],
        }],
        rights_list: [{ "rightsIdentifier" => "cc-by-2.5" }]
      )
    end
    let!(:works_2) do
      create_list(:doi, 2, aasm_state: "findable",
        types: { "resourceTypeGeneral" => "PhysicalObject" },
        creators: [{
          affiliation: [{
            "name": "2",
            "affiliationIdentifier": "https://ror.org/2",
            "affiliationIdentifierScheme": "ROR",
          }],
        }],
        rights_list: [{ "rightsIdentifier" => "cc-by-3.0" }]
      )
    end
    let!(:works_other) do
      create(:doi, aasm_state: "findable",
        types: { "resourceTypeGeneral" => "Preprint" },
        creators: [{
          affiliation: [
            {
              "name": "1",
              "affiliationIdentifier": "https://ror.org/1",
              "affiliationIdentifierScheme": "ROR",
            },
            {
              "name": "0",
              "affiliationIdentifier": "https://ror.org/0",
              "affiliationIdentifierScheme": "ROR",
            }
          ],
        }],
        rights_list: [
          { "rightsIdentifier" => "bsd-2-clause" },
          { "rightsIdentifier" => "bsd-3-clause" },
      ])
    end
    let!(:missing) do
      create_list(:doi, 3, aasm_state: "findable",
        creators: [{ affiliation: [] }],
        rights_list: [])
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
          variables: { first: 4, cursor: nil, facetCount: 5 }
        ).
          as_json

      expect(response.dig("data", "works", "totalCount")).to eq(18)
      expect(response.dig("data", "works", "resourceTypes")).to eq(
        [{ "count" => 5, "id" => "text", "title" => "Text" }, { "count" => 4, "id" => "journal-article", "title" => "Journal Article" }, { "count" => 3, "id" => "dataset", "title" => "Dataset" }, { "count" => 3, "id" => "image", "title" => "Image" }, { "count" => 2, "id" => "physical-object", "title" => "Physical Object" }, { "count" => 1, "id" => "__other__", "title" => "Other" }]
      )
      expect(response.dig("data", "works", "affiliations")).to eq(
        [{ "count" => 5, "id" => "ror.org/5", "title" => "5" }, { "count" => 4, "id" => "ror.org/4", "title" => "4" }, { "count" => 3, "id" => "__missing__", "title" => "Missing" }, { "count" => 3, "id" => "ror.org/3", "title" => "3" }, { "count" => 2, "id" => "ror.org/2", "title" => "2" }, { "count" => 2, "id" => "__other__", "title" => "Other" }]
      )
      expect(response.dig("data", "works", "licenses")).to eq(
        [{ "count" => 5, "id" => "cc-by-1.0", "title" => "CC-BY-1.0" }, { "count" => 4, "id" => "cc-by-2.0", "title" => "CC-BY-2.0" }, { "count" => 3, "id" => "__missing__", "title" => "Missing" }, { "count" => 3, "id" => "cc-by-2.5", "title" => "CC-BY-2.5" }, { "count" => 2, "id" => "cc-by-3.0", "title" => "CC-BY-3.0" }, { "count" => 2, "id" => "__other__", "title" => "Other" }]
      )
    end
  end

  describe "query creators and contributors", elasticsearch: true do
    let!(:work) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "name" => "Kristian Garza",
            "nameType" => "Personal",
            "affiliation" => {
              "name" => "Ruhr-University Bochum, Germany"
            }
          },
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
          }
        ],
        contributors: [
          {
            "givenName" => "Cody",
            "familyName" => "Ross",
            "name" => "Ross, Cody",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6876",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "contributorType" => "Editor",
            "affiliation" => {
              "name" => "Ruhr-University Bochum, Germany",
              "affiliationIdentifier": "https://ror.org/013meh722",
              "affiliationIdentifierScheme": "ROR"
            }
          },
          {
            "givenName" => "Kristian",
            "familyName" => "Garza",
            "contributorType" => "Editor",
            "affiliation" => [
              {
              "name" => "University of Cambridge"
            }
          ]
          },
        ],
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query($first: Int, $cursor: String, $facetCount: Int) {
        works(first: $first, after: $cursor, facetCount: $facetCount) {
          totalCount
          authors {
            id
            title
            count
          }
          creatorsAndContributors {
            id
            title
            count
          }
        }
      }"
    end

    it "returns the correct counts for authors and creatorsAndContributors" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "works", "authors").length()).to eq(1)
      expect(response.dig("data", "works", "creatorsAndContributors").length()).to eq(2)
    end

    it "returns the correct counts for the person_to_work_types multi-facet" do
      gql_query = """
        query($first: Int, $cursor: String, $facetCount: Int) {
          works(first: $first, after: $cursor, facetCount: $facetCount) {
            totalCount
            personToWorkTypesMultilevel {
              id
              title
              count
              inner {
                id
                title
                count
              }
            }
          }
        }
      """

      response = LupoSchema.execute(gql_query).as_json
      expect(response.dig("data", "works", "personToWorkTypesMultilevel").length()).to eq(2)
      expect(response.dig(
        "data", "works", "personToWorkTypesMultilevel", 0, "inner"
      ).length()).to eq(1)
    end
  end


  describe "query contributors with a mix of ORCID iDs and local identifiers", elasticsearch: true do
    let!(:work) do
      create(
        :doi,
        aasm_state: "findable",
        creators: [
          {
            "givenName" => "Cody",
            "familyName" => "Ross",
            "name" => "Ross, Cody",
            "nameIdentifiers" => [{
                "nameIdentifier" => "local identifier 1",
                "nameIdentifierScheme" => "local",
                "schemeUri" => "https://test.org",
            }],
          },
          {
            "name" => "Test Author",
            "nameType" => "Personal",
            "nameIdentifiers" => [{
                "nameIdentifier" => "local identifier 2",
                "nameIdentifierScheme" => "local",
                "schemeUri" => "test.org",
            }],
          },
          {
            "name" => "Bryceson Laing",
            "nameType" => "Personal",
            "nameIdentifiers" => [{
              "nameIdentifier" => "https://orcid.org/0000-0002-8249-1629",
              "nameIdentifierScheme" => "ORCID",
              "schemeUri" => "https://orcid.org",
            }],
          },
        ],
        contributors:  [
          {
            "name": "Contributor",
            "nameType": "Personal",
            "givenName": "Test 1",
            "familyName": "Contributor",
            "nameIdentifiers": [
              {
                  "schemeUri": "",
                  "nameIdentifier": "7482",
                  "nameIdentifierScheme": "local"
              }
            ],
            "contributorType" => "Editor"
          },
          {
            "name": "Contributor",
            "nameType": "Personal",
            "givenName": "Test 2",
            "familyName": "Contributor",
            "nameIdentifiers": [
              {
                  "schemeUri": "",
                  "nameIdentifier": "7482",
                  "nameIdentifierScheme": "local"
              },
            ],
            "contributorType" => "Editor"
          },
          {
              "name": "Joseph Rhoads",
              "nameType": "Personal",
              "givenName": "Joseph",
              "familyName": "Rhoads",
              "nameIdentifiers": [
                {
                    "schemeUri": "",
                    "nameIdentifier": "7483",
                    "nameIdentifierScheme": "local"
                },
                {
                    "schemeUri": "https://orcid.org",
                    "nameIdentifier": "https://orcid.org/0000-0003-3484-6876",
                    "nameIdentifierScheme": "ORCID"
                }
              ],
              "contributorType" => "Editor"
          }
        ]
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query($first: Int, $cursor: String, $facetCount: Int) {
        works(first: $first, after: $cursor, facetCount: $facetCount) {
          totalCount
          authors {
            id
            title
            count
          }
          creatorsAndContributors {
            id
            title
            count
          }
        }
      }"
    end

    it "returns the correct counts for authors, filtering out those that don't include ORCID iDs" do
      response = LupoSchema.execute(
        query,
        variables: { first: nil, cursor: nil, facetCount: 3 }
      ).as_json

      expect(response.dig("data", "works", "authors").length()).to eq(1)
    end


    it "returns the correct counts for creatorsAndContributors, filtering out those that don't include ORCID iDs" do
      response = LupoSchema.execute(
        query,
        variables: { first: nil, cursor: nil, facetCount: 3 }
      ).as_json

      expect(response.dig("data", "works", "creatorsAndContributors").length()).to eq(2)
    end
  end

  describe "query funders", elasticsearch: true do
    let!(:work) do
      create_list(
        :doi,
        10,
        aasm_state: "findable",
        funding_references: [
          { "funderName": "Fake Funders R Us: We're just in the way and should be skipped" },
          {
            "schemeUri": "https://ror.org",
            "funderName": "The French ministry of the Army, the French ministry of Ecological Transition,  the French Office for Biodiversity (OFB), the French Development Agency (AFD) and Météo France",
            "funderIdentifier": "https://ror.org/04tqhj682",
            "funderIdentifierType": "ROR"
          }
        ]
      )
    end

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query($first: Int, $cursor: String, $facetCount: Int) {
        works(first: $first, after: $cursor, facetCount: $facetCount) {
          totalCount
          funders {
            id
            title
            count
          }
        }
      }"
    end

    it "returns the correct counts for funders" do
      response = LupoSchema.execute(query).as_json
      expect(response.dig("data", "works", "funders").length()).to eq(1)
    end
  end

  describe "query with relationships", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }

    let!(:ref_target_dois) { create_list(:doi, 5, client: client, aasm_state: "findable") }
    let!(:reference_events) do
      ref_target_dois.each do |ref_target_doi|
        create(:event_for_crossref, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{ref_target_doi.doi}",
          relation_type_id: "references"
        })
      end
    end
    let!(:citation_target_dois) { create_list(:doi, 7, client: client, aasm_state: "findable") }
    let!(:citation_events) do
      citation_target_dois.each do |citation_target_doi|
        create(:event_for_datacite_crossref, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{citation_target_doi.doi}",
          relation_type_id: "is-referenced-by"
        })
      end
    end

    let!(:version_target_dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }
    let!(:version_events) do
      version_target_dois.each do |version_target_doi|
        create(:event_for_datacite_versions, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{version_target_doi.doi}"
        })
      end
    end

    let!(:part_target_dois) { create_list(:doi, 9, client: client, aasm_state: "findable") }
    let!(:part_events) do
      part_target_dois.each do |part_target_doi|
        create(:event_for_datacite_parts, {
          subj_id: "https://doi.org/#{doi.doi}",
          obj_id: "https://doi.org/#{part_target_doi.doi}",
          relation_type_id: "has-part"
        })
      end
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @response = LupoSchema.execute(query).as_json
    end


    let(:query) do
      "query {
        work(id: \"https://doi.org/#{
        doi.doi
      }\") {
          id
          partCount
          parts{
            nodes{
              id
            }
          }
          referenceCount
          references{
            nodes{
              id
            }
          }
          citationCount
          citations{
            nodes{
              id
            }
          }
          versionCount
          versions{
            nodes{
              id
            }
          }
          otherRelatedCount
          otherRelated{
            nodes{
              id
            }
          }
        }
      }"
    end

    it "references exist" do
      expect(@response.dig("data", "work", "referenceCount")).to eq(5)
      expect(@response.dig("data", "work", "references", "nodes").length).to eq(5)
    end

    it "citations exist" do
      expect(@response.dig("data", "work", "citationCount")).to eq(7)
      expect(@response.dig("data", "work", "citations", "nodes").length).to eq(7)
    end

    it "versions exist" do
      expect(@response.dig("data", "work", "versionCount")).to eq(3)
      expect(@response.dig("data", "work", "versions", "nodes").length).to eq(3)
    end

    it "parts exist" do
      expect(@response.dig("data", "work", "partCount")).to eq(9)
      expect(@response.dig("data", "work", "parts", "nodes").length).to eq(9)
    end

    it "other_relations should not include citations,parts,references" do
      expect(@response.dig("data", "work", "otherRelatedCount")).to eq(3)
      expect(@response.dig("data", "work", "otherRelated", "nodes").length).to eq(3)
    end
  end
end



describe "query with projects (TEMPORARY UNTIL PROJECT IS A RESOURCE_TYPE_GENERAL)", elasticsearch: true do
  let!(:text_projects) do
    create_list(:doi, 5, aasm_state: "findable",
      types: {
        "resourceTypeGeneral" => "Text",
        "resourceType" => "Project"
      },
    )
  end

  let!(:other_projects) do
    create_list(:doi, 5, aasm_state: "findable",
      types: {
        "resourceTypeGeneral" => "Other",
        "resourceType" => "Project"
      },
    )
  end

  let!(:invalid_projects) do
    create_list(:doi, 5, aasm_state: "findable",
      types: {
        "resourceTypeGeneral" => "Dataset",
        "resourceType" => "Project"
      },
    )
  end

  before do
    Doi.import
    sleep 2
  end

  let(:query) do
    "query($first: Int, $cursor: String, $resourceTypeId: String) {
      works(first: $first, after: $cursor, resourceTypeId: $resourceTypeId) {
        totalCount
        resourceTypes {
          id
          title
          count
        }
      }
    }"
  end

  it "returns project resource types" do
    response =
      LupoSchema.execute(
        query,
        variables: { first: 15, cursor: nil }
      ).
        as_json

    expect(response.dig("data", "works", "resourceTypes")).to eq(
      [{ "count" => 10, "id" => "project", "title" => "Project" }, { "count" => 5, "id" => "dataset", "title" => "Dataset" }]
    )
  end

  it "returns projects when querying works based on resource_type_id" do
    response =
      LupoSchema.execute(
        query,
        variables: { first: 15, cursor: nil, resourceTypeId: "Project" }
      ).
        as_json

    expect(response.dig("data", "works", "totalCount")).to eq(10)
  end
end

describe "query with resourceTypeId", elasticsearch: true do
  let!(:instrument_doi) do
    create(:doi, aasm_state: "findable",
      types: {
        "resourceTypeGeneral" => "Instrument",
      },
    )
  end

  let!(:study_registration_doi) do
    create(:doi, aasm_state: "findable",
      types: {
        "resourceTypeGeneral" => "StudyRegistration",
      },
    )
  end

  before do
    Doi.import
    sleep 2
  end

  let(:query) do
    "query($first: Int, $cursor: String, $resourceTypeId: String) {
      works(first: $first, after: $cursor, resourceTypeId: $resourceTypeId) {
        totalCount
        resourceTypes {
          id
          title
          count
        }
        nodes {
          doi
          types {
            resourceTypeGeneral
          }
        }
      }
    }"
  end

  it "returns instrument resource types" do
    response =
      LupoSchema.execute(
        query,
        variables: { resourceTypeId: "instrument" }
      ).
        as_json

    expect(response.dig("data", "works", "resourceTypes")).to eq(
      [{ "count" => 1, "id" => "instrument", "title" => "Instrument" }]
    )
    expect(response.dig("data", "works", "nodes", 0, "doi")).to eq(instrument_doi.doi.downcase)
    expect(response.dig("data", "works", "nodes", 0, "types", "resourceTypeGeneral")).to eq("Instrument")
  end

  it "returns study registration resource types" do
    response =
      LupoSchema.execute(
        query,
        variables: { resourceTypeId: "study-registration" }
      ).
        as_json

    expect(response.dig("data", "works", "resourceTypes")).to eq(
      [{ "count" => 1, "id" => "study-registration", "title" => "Study Registration" }]
    )
    expect(response.dig("data", "works", "nodes", 0, "doi")).to eq(study_registration_doi.doi.downcase)
    expect(response.dig("data", "works", "nodes", 0, "types", "resourceTypeGeneral")).to eq("StudyRegistration")
  end
end