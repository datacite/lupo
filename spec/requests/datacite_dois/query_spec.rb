# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request, vcr: true, prefix_pool_size: 11 do
  def import_doi_index
    DataciteDoi.import
    DataciteDoi.__elasticsearch__.client.indices.refresh(index: DataciteDoi.index_name)
  end

  def clear_doi_index
    DataciteDoi.__elasticsearch__.client.delete_by_query(index: DataciteDoi.index_name, body: { query: { match_all: {} } })
    DataciteDoi.__elasticsearch__.client.indices.refresh(index: DataciteDoi.index_name)
  end

  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: encrypt_password_sha256(ENV["MDS_PASSWORD"]), re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "GET /dois with query", elasticsearch: true, prefix_pool_size: 4 do
    let!(:doi) do
      create(:doi, client: client, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian J.",
        "name" => "Garza, Kristian J.",
        "nameIdentifiers" => [{ "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID", "schemeUri" => "https://orcid.org" }],
        "nameType" => "Personal",
        "affiliation": [
          {
            "name": "Freie Universität Berlin",
            "affiliationIdentifier": "https://ror.org/046ak2485",
            "affiliationIdentifierScheme": "ROR",
          },
        ],
      }], funding_references:
      [{
        "funderIdentifier" => "https://doi.org/10.13039/501100009053",
        "funderIdentifierType" => "Crossref Funder ID",
        "funderName" => "The Wellcome Trust DBT India Alliance",
      }], subjects:
      [{
        "subject": "FOS: Computer and information sciences",
        "schemeUri": "http://www.oecd.org/science/inno/38235147.pdf",
        "subjectScheme": "Fields of Science and Technology (FOS)",
      }])
    end
    let!(:dois) { create_list(:doi, 3, aasm_state: "findable") }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns dois with short orcid id", vcr: true do
      get "/dois?user-id=0000-0003-3484-6875", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with orcid id", vcr: true do
      get "/dois?user-id=orcid.org/0000-0003-3484-6875", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with orcid id as url", vcr: true do
      get "/dois?user-id=https://orcid.org/0000-0003-3484-6875", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with crossref funder id", vcr: true do
      get "/dois?funder-id=10.13039/501100009053", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "fundingReferences")).to eq([{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }])
    end

    it "returns dois with multiple crossref funder id", vcr: true do
      get "/dois?funder-id=10.13039/501100009053,10.13039/501100000735", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "fundingReferences")).to eq([{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }])
    end

    it "returns dois with crossref funder id as url", vcr: true do
      get "/dois?funder-id=https://doi.org/10.13039/501100009053", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "fundingReferences")).to eq([{ "funderIdentifier" => "https://doi.org/10.13039/501100009053", "funderIdentifierType" => "Crossref Funder ID", "funderName" => "The Wellcome Trust DBT India Alliance" }])
    end

    it "returns dois with short ror id", vcr: true do
      get "/dois?affiliation-id=046ak2485&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => [{ "name" => "Freie Universität Berlin", "affiliationIdentifier" => "https://ror.org/046ak2485", "affiliationIdentifierScheme" => "ROR" }], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with ror id", vcr: true do
      get "/dois?affiliation-id=ror.org/046ak2485&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => [{ "name" => "Freie Universität Berlin", "affiliationIdentifier" => "https://ror.org/046ak2485", "affiliationIdentifierScheme" => "ROR" }], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with ror id as url", vcr: true do
      get "/dois?affiliation-id=https://ror.org/046ak2485&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => [{ "name" => "Freie Universität Berlin", "affiliationIdentifier" => "https://ror.org/046ak2485", "affiliationIdentifierScheme" => "ROR" }], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with re3data id", vcr: true do
      get "/dois?re3data-id=10.17616/R3XS37&include=client", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("included", 0, "attributes", "re3data")).to eq("https://doi.org/10.17616/r3xs37")
    end

    it "returns dois with re3data id as url", vcr: true do
      get "/dois?re3data-id=https://doi.org/10.17616/R3XS37&include=client", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("included", 0, "attributes", "re3data")).to eq("https://doi.org/10.17616/r3xs37")
    end

    it "returns dois with full name", vcr: true do
      get "/dois?query=Kristian%20Garza&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => [{ "name" => "Freie Universität Berlin", "affiliationIdentifier" => "https://ror.org/046ak2485", "affiliationIdentifierScheme" => "ROR" }], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns affiliation as strings when affiliation=false", vcr: true do
      get "/dois?query=Kristian%20Garza&affiliation=false", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns affiliation as strings when affiliation is a non-true value", vcr: true do
      get "/dois?query=Kristian%20Garza&affiliation=foo", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end

    it "returns dois with field of science", vcr: true do
      get "/dois?field-of-science=computer_and_information_sciences", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("meta", "fieldsOfScience")).to eq([{ "count" => 1, "id" => "computer_and_information_sciences", "title" => "Computer and information sciences" }])
      expect(json.dig("data", 0, "attributes", "creators")).to eq([{ "name" => "Garza, Kristian J.", "nameType" => "Personal", "givenName" => "Kristian J.", "familyName" => "Garza", "affiliation" => ["Freie Universität Berlin"], "nameIdentifiers" => [{ "schemeUri" => "https://orcid.org", "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme" => "ORCID" }] }])
    end
  end

  describe "GET /dois with sort", elasticsearch: true do
    let!(:dois) {
      [
        create(:doi, titles: [{ "title" => "Brad" }]),
        create(:doi, titles: [{ "title" => "Zack" }]),
        create(:doi, titles: [{ "title" => "Alphonso" }, { "title" => "Zorro", "titleType" => "AlternativeTitle" }]),
        create(:doi, titles: [{ "title" => "Corey" }]),
        create(:doi, titles: [{ "title" => "Adorno" }]),
        create(:doi, titles: [{ "title" => "acorn" }]),
        create(:doi, titles: [{ "title" => "zoey" }]),
        create(:doi, titles: nil),
        create(:doi, titles: []),
        create(:doi, titles: [{ "title" => "" }]),
      ]
    }

    before do
      import_doi_index
    end

    it "returns dois in ascending title sort order" do
      get "/dois?sort=title", nil, headers

      result = json.dig("data")

      expect(result.dig(0, "attributes", "titles")).to eq(dois[9].titles)
      expect(result.dig(1, "attributes", "titles")).to eq(dois[5].titles)
      expect(result.dig(2, "attributes", "titles")).to eq(dois[4].titles)
      expect(result.dig(3, "attributes", "titles")).to eq(dois[2].titles)
    end

    it "returns dois in descending title sort order" do
      get "/dois?sort=-title", nil, headers

      result = json.dig("data")

      expect(result.dig(0, "attributes", "titles")).to eq(dois[6].titles)
      expect(result.dig(1, "attributes", "titles")).to eq(dois[1].titles)
      expect(result.dig(2, "attributes", "titles")).to eq(dois[3].titles)
    end
  end

  describe "GET /dois for dissertations", elasticsearch: true, vcr: true, prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation" }, client: client, aasm_state: "findable") }

    before do
      import_doi_index
    end

    it "filter for dissertations" do
      get "/dois?resource-type=Dissertation", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
      expect(json.dig("data", 0, "attributes", "publicationYear")).to eq(2011)
      expect(json.dig("data", 0, "attributes", "types")).to eq("bibtex" => "phdthesis", "citeproc" => "thesis", "resourceType" => "Dissertation", "resourceTypeGeneral" => "Text", "ris" => "THES", "schemaOrg" => "Thesis")
    end
  end

  describe "GET /dois for instruments", elasticsearch: true, vcr: true, prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Other", "resourceType" => "Instrument" }, client: client, aasm_state: "findable") }

    before do
      import_doi_index
    end

    it "filter for instruments" do
      get "/dois?resource-type=Instrument", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
      expect(json.dig("data", 0, "attributes", "publicationYear")).to eq(2011)
      expect(json.dig("data", 0, "attributes", "types")).to eq("bibtex" => "misc", "citeproc" => "article", "resourceType" => "Instrument", "resourceTypeGeneral" => "Other", "ris" => "GEN", "schemaOrg" => "CreativeWork")
    end
  end

  describe "GET /dois for interactive resources", elasticsearch: true, vcr: true, prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "InteractiveResource", "resourceType" => "Presentation" }, client: client, aasm_state: "findable") }

    before do
      import_doi_index
    end

    it "filter for interactive resources" do
      get "/dois?resource-type-id=interactive-resource", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
      expect(json.dig("data", 0, "attributes", "publicationYear")).to eq(2011)
      expect(json.dig("data", 0, "attributes", "types")).to eq("bibtex" => "misc", "citeproc" => "article", "resourceType" => "Presentation", "resourceTypeGeneral" => "InteractiveResource", "ris" => "GEN", "schemaOrg" => "CreativeWork")
      expect(json.dig("meta", "resourceTypes")).to eq([{ "count" => 3, "id" => "interactive-resource", "title" => "Interactive Resource" }])
    end

    it "filter for interactive resources no facets" do
      get "/dois?resource-type-id=interactive-resource&disable-facets=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
      expect(json.dig("data", 0, "attributes", "publicationYear")).to eq(2011)
      expect(json.dig("data", 0, "attributes", "types")).to eq("bibtex" => "misc", "citeproc" => "article", "resourceType" => "Presentation", "resourceTypeGeneral" => "InteractiveResource", "ris" => "GEN", "schemaOrg" => "CreativeWork")
      expect(json.dig("meta")).to eq("page" => 1, "total" => 3, "totalPages" => 1)
    end
  end

  describe "GET /dois for fake resources", elasticsearch: true, vcr: true, prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Fake", "resourceType" => "Presentation" }, client: client) }

    before do
      import_doi_index
    end

    it "filter for fake resources returns no results" do
      get "/dois?resource-type-id=fake", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(0)
      expect(json.dig("meta", "total")).to eq(0)
    end
  end
end
