# frozen_string_literal: true

require "rails_helper"
include Passwordable

def import_doi_index
  DataciteDoi.import
  DataciteDoi.__elasticsearch__.client.indices.refresh(index: DataciteDoi.index_name)
end

def clear_doi_index
  DataciteDoi.__elasticsearch__.client.delete_by_query(index: DataciteDoi.index_name, body: { query: { match_all: {} } })
  DataciteDoi.__elasticsearch__.client.indices.refresh(index: DataciteDoi.index_name)
end


describe DataciteDoisController, type: :request, vcr: true do
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


  describe "GET /dois", prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable", version_info: "testtag") }

    before do
      clear_doi_index
      import_doi_index
      @dois = DataciteDoi.query(nil, page: { cursor: [], size: 10 }).results.to_a
    end

    it "returns dois" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
    end

    it "returns dois with scroll" do
      get "/dois?page[scroll]=1m&page[size]=4", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta", "scroll-id")).to be_present
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta", "scroll-id")).to be_present
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta", "scroll-id")).to be_present
      expect(json.dig("links", "next")).to be_nil
    end

    it "returns dois with offset" do
      get "/dois?page[number]=1&page[size]=4", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/dois?page%5Bnumber%5D=2&page%5Bsize%5D=4")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/dois?page%5Bnumber%5D=3&page%5Bsize%5D=4")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "next")).to be_nil
    end

    it "returns correct page links when results is exactly divisible by page size" do
      get "/dois?page[number]=1&page[size]=5", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/dois?page%5Bnumber%5D=2&page%5Bsize%5D=5")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "next")).to be_nil
    end

    it "returns a blank resultset when page is above max page" do
      get "/dois?page[number]=3&page[size]=5", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(0)
      expect(json.dig("meta", "totalPages")).to eq(2)
      expect(json.dig("meta", "page")).to eq(3)
      expect(json.dig("links", "next")).to be_nil
    end

    it "returns dois with cursor" do
      get "/dois?page[cursor]&page[size]=4", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("data", 3, "id")).to eq(@dois[3].uid)
      expect(json.dig("meta", "total")).to eq(10)
      cursor = Rack::Utils.parse_query(json.dig("links", "next").split("?", 2).last).fetch("page[cursor]", nil)
      expect(Base64.urlsafe_decode64(cursor).split(",").last).to eq(@dois[3].uid)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("data", 3, "id")).to eq(@dois[7].uid)
      expect(json.dig("meta", "total")).to eq(10)
      cursor = Rack::Utils.parse_query(json.dig("links", "next").split("?", 2).last).fetch("page[cursor]", nil)
      expect(Base64.urlsafe_decode64(cursor).split(",").last).to eq(@dois[7].uid)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json.dig("data", 1, "id")).to eq(@dois[9].uid)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "next")).to be_nil
    end

    it "returns dois with version query", vcr: true do
      get "/dois?query=version:testtag", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      json["data"].each do |doi|
        expect(doi.dig("attributes")).to include("version")
      end
    end

    it "returns dois with extra detail", vcr: true do
      get "/dois?detail=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      json["data"].each do |doi|
        expect(doi.dig("attributes")).to include("xml")
      end
    end

    it "returns related provider when detail is enabled", vcr: true do
      get "/dois?detail=true", nil, headers

      expect(last_response.status).to eq(200)
      json["data"].each do |doi|
        expect(doi.dig("relationships", "provider", "data", "id")).to eq(provider.symbol.downcase)
      end
    end

    it "applies field filters for a single filter" do
      get "/dois?fields[dois]=id", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      json["data"].each do |doi|
        expect(doi).to include("id")
        expect(doi).to include("attributes")
        expect(doi).to include("relationships")
        expect(doi.dig("attributes")).to eq({})
        expect(doi.dig("relationships")).to eq({})
      end
    end

    it "applies field filters for multiple filters" do
      get "/dois?fields[dois]=id,subjects", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      json["data"].each do |doi|
        expect(doi).to include("id")
        expect(doi).to include("attributes")
        expect(doi).to include("relationships")
        expect(doi.dig("attributes")).to have_key("subjects")
        expect(doi.dig("attributes")).to_not have_key("creators")
        expect(doi.dig("relationships")).to eq({})
      end
    end

    it "preserves field filters in pagination links" do
      get "/dois?fields[dois]=id&page[size]=2&page[number]=1", nil, headers

      expect(last_response.status).to eq(200)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/dois?fields%5Bdois%5D=id&page%5Bnumber%5D=2&page%5Bsize%5D=2")

      get "/dois?fields[dois]=id,subjects&page[size]=2&page[number]=1", nil, headers

      expect(last_response.status).to eq(200)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/dois?fields%5Bdois%5D=id%2Csubjects&page%5Bnumber%5D=2&page%5Bsize%5D=2")
    end

    it "returns default facets" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)

      expect(json.dig("meta").length).to eq(21)
      expect(json.dig("meta", "states")).to be_truthy
      expect(json.dig("meta", "resourceTypes")).to be_truthy
      expect(json.dig("meta", "created")).to be_truthy
      expect(json.dig("meta", "published")).to be_truthy
      expect(json.dig("meta", "registered")).to be_truthy
      expect(json.dig("meta", "providers")).to be_truthy
      expect(json.dig("meta", "clients")).to be_truthy
      expect(json.dig("meta", "affiliations")).to be_truthy
      expect(json.dig("meta", "prefixes")).to be_truthy
      expect(json.dig("meta", "certificates")).to be_truthy
      expect(json.dig("meta", "licenses")).to be_truthy
      expect(json.dig("meta", "schemaVersions")).to be_truthy
      expect(json.dig("meta", "linkChecksStatus")).to be_truthy
      expect(json.dig("meta", "subjects")).to be_truthy
      expect(json.dig("meta", "fieldsOfScience")).to be_truthy
      expect(json.dig("meta", "citations")).to be_truthy
      expect(json.dig("meta", "views")).to be_truthy
      expect(json.dig("meta", "downloads")).to be_truthy

      expect(json.dig("meta", "clientTypes")).to eq(nil)
      expect(json.dig("meta", "languages")).to eq(nil)
      expect(json.dig("meta", "creatorsAndContributors")).to eq(nil)
    end

    it "returns no facets when disable-facets is set" do
      get "/dois?disable-facets=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta").length).to eq(3)
      expect(json.dig("meta", "states")).to eq(nil)
    end

    it "returns specified facets when facets is set" do
      get "/dois?facets=client_types,registrationAgencies, clients,languages,creators_and_contributors,made_up_facet", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta").length).to eq(8)
      expect(json.dig("meta", "states")).to eq(nil)
      expect(json.dig("meta", "clientTypes")).to be_truthy
      expect(json.dig("meta", "registrationAgencies")).to be_truthy
      expect(json.dig("meta", "clients")).to be_truthy
      expect(json.dig("meta", "languages")).to be_truthy
      expect(json.dig("meta", "creatorsAndContributors")).to be_truthy
      expect(json.dig("meta", "madeUpFacet")).to eq(nil)
      expect(json.dig("meta", "made_up_facet")).to eq(nil)
    end
  end

  describe "GET /dois with nil publisher values", elsasticsearch: true, prefix_pool_size: 1 do
    let!(:doi) { create(:doi, client: client, publisher_obj: nil) }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns nil publisher when publisher param is not set" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].length).to eq(1)
      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(nil)
      end
    end

    it "returns nil publisher when publisher param is set to true" do
      get "/dois?publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].length).to eq(1)
      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(nil)
      end
    end
  end

  describe "GET /dois/:id with nil publisher values", elasticsearch: false, prefix_pool_size: 1 do
    let!(:doi) { create(:doi, client: client, publisher: nil) }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns nil publisher when publisher param is not set" do
      get "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("attributes", "publisher")).to eq(nil)
    end

    it "returns nil publisher when publisher param is set to true" do
      get "/dois/#{doi.doi}?publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("attributes", "publisher")).to eq(nil)
    end
  end

  describe "GET /dois with publisher values", elasticsearch: false, prefix_pool_size: 1 do
    let!(:dryad_publisher_dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }
    let!(:datacite_publisher_doi) { create(:doi, client: client, aasm_state: "findable", publisher:
        {
          "name": "DataCite",
          "publisherIdentifier": "https://ror.org/04wxnsj81",
          "publisherIdentifierScheme": "ROR",
          "schemeUri": "https://ror.org/",
          "lang": "en",
        }
      )
    }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns publisher hashes when publisher param is set to true" do
      get "/dois?publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(11)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher").class).to be(Hash)
        expect(doi.dig("attributes", "publisher").keys.length).to be(5)
        doi.dig("attributes", "publisher").each do |key, value|
          expect(value).to be_present
        end
      end
    end

    it "returns publisher strings when publisher param is not set" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(11)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher").class).to be(String)
        expect(doi.dig("attributes", "publisher")).to be_present
      end
    end

    it "filters by publisher using query" do
      get "/dois?query=datacite&publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end

    it "filters by publisher using query string query" do
      get "/dois?query=publisher:datacite&publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end

    it "filters by publisher name using query string query" do
      get "/dois?query=publisher.name:datacite&publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end

    it "filters by publisherIdentifier using query string query" do
      get "/dois?query=publisher.publisherIdentifier:\"https://ror.org/04wxnsj81\"&publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)

      json["data"].each do |doi|
        expect(doi.dig("attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end
  end

  describe "GET /dois/:id with publisher values", prefix_pool_size: 1 do
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }

    it "returns publisher hash when publisher param is set to true" do
      get "/dois/#{doi.doi}?publisher=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "publisher")).to eq(
        {
          "name" => "Dryad Digital Repository",
          "publisherIdentifier" => "https://ror.org/00x6h5n95",
          "publisherIdentifierScheme" => "ROR",
          "schemeUri" => "https://ror.org/",
          "lang" => "en"
        }
      )
    end

    it "returns publisher string when publisher param is not set" do
      get "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "publisher")).to eq("Dryad Digital Repository")
    end
  end

  describe "GET /dois/:id with agency values", prefix_pool_size: 1 do
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }

    it "returns agency values when flag is set" do
      get "/dois/#{doi.doi}?include_other_registration_agencies=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "agency")).to eq("datacite")
    end

    it "does not returns agency values when flag isn't set" do
      get "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes")).to_not have_key("agency")
    end
  end

  describe "GET /dois search with agency values", prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns agency values when flag is set" do
      get "/dois?include_other_registration_agencies=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", 0, "attributes", "agency")).to eq("datacite")
    end

    it "does not returns agency values when flag isn't set" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", 0, "attributes")).to_not have_key("agency")
    end
  end

  describe "GET /dois with client-type filter", prefix_pool_size: 3 do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable", version_info: "testtag") }
    let(:client_igsn_id_catalog) { create(:client, provider: provider, client_type: "igsnCatalog") }
    let(:client_raid_registry) { create(:client, provider: provider, client_type: "raidRegistry") }
    let!(:doi_igsn_id) { create(:doi, client: client_igsn_id_catalog, aasm_state: "findable", types: { "resourceTypeGeneral": "PhysicalObject" }) }
    let!(:doi_raid_registry) { create(:doi, client: client_raid_registry, aasm_state: "findable", types: { "resourceTypeGeneral": "Other", "resourceType": "Project" }) }
    let!(:dois_other) { create_list(:doi, 5, client: client_igsn_id_catalog, aasm_state: "findable", types: { "resourceTypeGeneral": "Dataset" }) }

    before do
      clear_doi_index
      import_doi_index
    end


    it "filters by repository client_type when client-type is set", vcr: true do
      get "/dois?client-type=repository", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
    end

    it "returns additional createdByMonth meta attribute and only DOIs with resourceTypeGeneral=PhysicalObject and client_type=igsnCatalog when client-type is set to igsnCatalog", vcr: true do
      get "/dois?client-type=igsnCatalog", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      expect(json.dig("data", 0, "id")).to eq(doi_igsn_id.uid)
      expect(json.dig("meta", "createdByMonth", 0, "title")).to eq(doi_igsn_id.created.to_time.strftime("%Y-%m"))
    end

    it "filters by raidRegistry client_type when client-type is set", vcr: true do
      get "/dois?client-type=raidRegistry", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      expect(json.dig("data", 0, "id")).to eq(doi_raid_registry.uid)
    end
  end

  describe "GET /dois with resource-type-id filter", elasticsearch: false, prefix_pool_size: 1 do
    let!(:instrument_doi) { create(:doi, client: client, aasm_state: "findable", types: { "resourceTypeGeneral": "Instrument" }) }
    let!(:study_registration_doi) { create(:doi, client: client, aasm_state: "findable", types: { "resourceTypeGeneral": "StudyRegistration" }) }

    before do
      clear_doi_index
      import_doi_index
    end

    it "filters for Instrument dois when resource-type-id is set to instrument", vcr: true do
      get "/dois?resource-type-id=instrument", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("meta", "resourceTypes", 0)).to eq(
        {
          "id" => "instrument",
          "title" => "Instrument",
          "count" => 1
        }
      )
      expect(json.dig("meta", "resourceTypes").length).to eq(1)
      expect(json.dig("data", 0, "attributes", "types", "resourceTypeGeneral")).to eq("Instrument")
    end

    it "filters for StudyRegistration dois when resource-type-id is set to instrument", vcr: true do
      get "/dois?resource-type-id=study-registration", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("meta", "resourceTypes", 0)).to eq(
        {
          "id" => "study-registration",
          "title" => "Study Registration",
          "count" => 1
        }
      )
      expect(json.dig("meta", "resourceTypes").length).to eq(1)
      expect(json.dig("data", 0, "attributes", "types", "resourceTypeGeneral")).to eq("StudyRegistration")
    end
  end

  describe "GET /dois with query", elasticsearch: true do
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

  describe "GET /dois/:id", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }

    before do
      import_doi_index
    end

    context "when the record exists" do
      it "returns the Doi" do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        result = json.dig("data")

        expect(result.dig("attributes", "doi")).to eq(doi.doi.downcase)
        expect(result.dig("attributes", "titles")).to eq(doi.titles)
        expect(result.dig("attributes", "identifiers")).to eq([{ "identifier" => "pk-1234", "identifierType" => "publisher ID" }])
        expect(result.dig("attributes", "alternateIdentifiers")).to eq([{ "alternateIdentifier" => "pk-1234", "alternateIdentifierType" => "publisher ID" }])
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/dois/10.5256/xxxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors" => [{ "status" => "404", "title" => "The resource you are looking for doesn't exist." }])
      end
    end

    context "provider_admin" do
      let(:provider_bearer) { Client.generate_token(role_id: "provider_admin", uid: provider.symbol, provider_id: provider.symbol.downcase, password: provider.password) }
      let(:provider_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + provider_bearer } }

      it "returns the Doi" do
        get "/dois/#{doi.doi}", nil, provider_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
      end
    end

    context "anonymous user" do
      it "returns the Doi" do
        get "/dois/#{doi.doi}"

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors" => [{ "status" => "404", "title" => "The resource you are looking for doesn't exist." }])
      end
    end

    context "creators started as an object not array" do
      let(:doi) do
        create(:doi, client: client, creators:
        {
          "nameType" => "Personal",
          "name" => "John Doe",
          "affiliation" => [],
          "nameIdentifiers" => [],
        })
      end

      it "returns the creators as list" do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "creators")).to eq([doi.creators])
      end
    end

    context "nameIdentifiers started as an object not array" do
      let(:doi) do
        create(:doi, client: client, creators:
        [{
          "nameType" => "Personal",
          "name" => "John Doe",
          "affiliation" => [],
          "nameIdentifiers": {
            "nameIdentifier": "http://viaf.org/viaf/4934600",
            "nameIdentifierScheme": "VIAF"
          },
        }])
      end

      it "returns the nameIdentifiers as list" do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "creators", 0, "nameIdentifiers")).to eq([{ "nameIdentifier" => "http://viaf.org/viaf/4934600", "nameIdentifierScheme" => "VIAF" }])
      end
    end

    context "when the publisher param is set to true" do
      it "returns the Doi" do
        get "/dois/#{doi.doi}?publisher=true", nil, headers

        expect(last_response.status).to eq(200)
        result = json.dig("data")

        expect(result.dig("attributes", "doi")).to eq(doi.doi.downcase)
        expect(result.dig("attributes", "titles")).to eq(doi.titles)
        expect(result.dig("attributes", "identifiers")).to eq([{ "identifier" => "pk-1234", "identifierType" => "publisher ID" }])
        expect(result.dig("attributes", "alternateIdentifiers")).to eq([{ "alternateIdentifier" => "pk-1234", "alternateIdentifierType" => "publisher ID" }])
        expect(result.dig("attributes", "publisher")).to eq(
          {
            "name" => "Dryad Digital Repository",
            "publisherIdentifier" => "https://ror.org/00x6h5n95",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en"
          }
        )
      end
    end
  end

  describe "GET /dois for dissertations", elasticsearch: true, vcr: true do
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

  describe "GET /dois for instruments", elasticsearch: true, vcr: true do
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

  describe "GET /dois for interactive resources", elasticsearch: true, vcr: true do
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

  describe "GET /dois for fake resources", elasticsearch: true, vcr: true do
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

  describe "state" do
    let(:doi_id) { "10.14454/4K3M-NYVG" }
    let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
    let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
    let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

    context "initial state draft", elasticsearch: true do
      let!(:doi) { create(:doi, client: client) }

      before do
        import_doi_index
      end

      it "fetches the record" do
        get "/dois/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "url")).to eq(doi.url)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "titles")).to eq(doi.titles)
        expect(json.dig("data", "attributes", "isActive")).to be false
        expect(json.dig("data", "attributes", "state")).to eq("draft")
      end
    end

    context "register" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "event" => "register",
            },
          },
        }
      end

      it "creates the record" do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq(doi_id.downcase)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "isActive")).to be false
        expect(json.dig("data", "attributes", "state")).to eq("registered")
      end
    end

    context "register no url" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "event" => "register",
            },
          },
        }
      end

      it "creates the record" do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "url", "title" => "Can't be blank", "uid" => "10.14454/4k3m-nyvg" }])
      end
    end

    context "publish" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "url" => "http://www.bl.uk/pdf/pat.pdf",
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "attributes", "doi")).to eq(doi_id.downcase)
        expect(json.dig("data", "attributes", "url")).to eq("http://www.bl.uk/pdf/pat.pdf")
        expect(json.dig("data", "attributes", "isActive")).to be true
        expect(json.dig("data", "attributes", "state")).to eq("findable")
      end
    end

    context "publish no url" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi_id}", valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "url", "title" => "Can't be blank", "uid" => "10.14454/4k3m-nyvg" }])
      end
    end

    context "hide" do
      let(:doi) { create(:doi, doi: "10.14454/1x4x-9056", client: client, url: "https://datacite.org", aasm_state: "findable") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "event" => "hide",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "isActive")).to be false
        expect(json.dig("data", "attributes", "state")).to eq("registered")
      end
    end

    context "hide with reason" do
      let(:doi) { create(:doi, doi: "10.14454/0etfa87k9p", client: client, url: "https://datacite.org", aasm_state: "findable") }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "event" => "hide",
              "reason" => "withdrawn by author",
            },
          },
        }
      end

      it "updates the record" do
        patch "/dois/#{doi.doi}", valid_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", "attributes", "isActive")).to be false
        expect(json.dig("data", "attributes", "reason")).to eq("withdrawn by author")
        expect(json.dig("data", "attributes", "state")).to eq("registered")
      end
    end
  end

  describe "PUT /dois/:id" do
    context "update publisher" do
      let(:doi) { create(:doi, doi: "10.14454/10703", publisher: nil, client: client) }
      let(:xml) { Base64.strict_encode64(file_fixture("datacite-example-full-v4.5.xml").read) }

      let(:publisher_as_string_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "publisher" => "DataCite",
              "event" => "publish",
            }
          }
        }
      end

      let(:publisher_as_obj_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "publisher" => {
                "name" => "DataCite",
                "publisherIdentifier" => "https://ror.org/04wxnsj81",
                "publisherIdentifierScheme" => "ROR",
                "schemeUri" => "https://ror.org/",
                "lang" => "en",
              },
              "event" => "publish",
            }
          }
        }
      end

      let(:publisher_obj_in_xml) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "xml" => xml,
              "event" => "publish",
            },
          },
        }
      end

      it "with publisher as string" do
        put "/dois/#{doi.doi}", publisher_as_string_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")

        expect(Doi.where(doi: doi.doi).first.publisher).to eq(
          {
            "name" => "DataCite",
          }
        )
      end

      it "with publisher as string with publisher param set to true" do
        put "/dois/#{doi.doi}?publisher=true", publisher_as_string_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
          }
        )
      end

      it "with publisher as object" do
        put "/dois/#{doi.doi}", publisher_as_obj_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq("DataCite")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("publisher").content).to eq("DataCite")
        expect(doc.at_css("publisher")["publisherIdentifier"]).to eq("https://ror.org/04wxnsj81")
        expect(doc.at_css("publisher")["publisherIdentifierScheme"]).to eq("ROR")
        expect(doc.at_css("publisher")["schemeURI"]).to eq("https://ror.org/")
        expect(doc.at_css("publisher")["xml:lang"]).to eq("en")

        expect(Doi.where(doi: doi.doi).first.publisher).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end

      it "with publisher as object with publisher param set to true" do
        put "/dois/#{doi.doi}?publisher=true", publisher_as_obj_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq(
          {
            "name" => "DataCite",
            "publisherIdentifier" => "https://ror.org/04wxnsj81",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end

      it "with publisher obj in xml" do
        put "/dois/#{doi.doi}", publisher_obj_in_xml, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq("Example Publisher")

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("publisher").content).to eq("Example Publisher")
        expect(doc.at_css("publisher")["publisherIdentifier"]).to eq("https://ror.org/04z8jg394")
        expect(doc.at_css("publisher")["publisherIdentifierScheme"]).to eq("ROR")
        expect(doc.at_css("publisher")["schemeURI"]).to eq("https://ror.org/")
        expect(doc.at_css("publisher")["xml:lang"]).to eq("en")

        expect(Doi.where(doi: "10.14454/10703").first.publisher).to eq(
          {
            "name" => "Example Publisher",
            "publisherIdentifier" => "https://ror.org/04z8jg394",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end

      it "with publisher obj in xml with publisher param set to true" do
        put "/dois/#{doi.doi}?publisher=true", publisher_obj_in_xml, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "schemaVersion")).to eq("http://datacite.org/schema/kernel-4")
        expect(json.dig("data", "attributes", "state")).to eq("findable")
        expect(json.dig("data", "attributes", "publisher")).to eq(
          {
            "name" => "Example Publisher",
            "publisherIdentifier" => "https://ror.org/04z8jg394",
            "publisherIdentifierScheme" => "ROR",
            "schemeUri" => "https://ror.org/",
            "lang" => "en",
          }
        )
      end
    end
  end

  describe "DELETE /dois/:id" do
    let(:doi) { create(:doi, client: client, aasm_state: "draft") }

    it "returns status code 204" do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end

  describe "DELETE /dois/:id findable state" do
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }

    it "returns status code 405" do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json["errors"]).to eq([{ "status" => "405", "title" => "Method not allowed" }])
    end
  end

  describe "POST /dois/set-url", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client, url: nil) }

    it "returns dois" do
      post "/dois/set-url", nil, admin_headers

      expect(last_response.status).to eq(200)
      expect(json["message"]).to eq("Adding missing URLs queued.")
    end
  end

  describe "GET /dois/random" do
    it "returns random doi" do
      get "/dois/random?prefix=10.14454", headers: headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to start_with("10.14454")
    end
  end

  describe "GET /dois/<doi> linkcheck results", elasticsearch: true do
    let(:landing_page) do
      {
        "checked" => Time.zone.now.utc.iso8601,
        "status" => 200,
        "url" => "http://example.com",
        "contentType" => "text/html",
        "error" => nil,
        "redirectCount" => 0,
        "redirectUrls" => [],
        "downloadLatency" => 200,
        "hasSchemaOrg" => true,
        "schemaOrgId" => "10.14454/10703",
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true,
      }
    end

    # Setup an initial DOI with results will check permissions against.
    let!(:doi) do
      create(:doi, doi: "10.24425/2210181332",
                   client: client,
                   state: "findable",
                   event: "publish",
                   landing_page: landing_page)
    end

    # Create a different dummy client and a doi with entry associated
    # This is so we can test clients accessing others information
    let(:other_client) { create(:client, provider: provider, symbol: "DATACITE.DNE", password: "notarealpassword") }
    let(:other_doi) do
      create(:doi, doi: "10.24425/2210181332",
                   client: other_client,
                   state: "findable",
                   event: "publish",
                   landing_page: landing_page)
    end

    before do
      import_doi_index
    end

    context "anonymous get" do
      let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json" } }

      it "returns without landing page results" do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "landingPage")).to eq(nil)
      end
    end

    context "client authorised get own dois" do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

      it "returns with landing page results" do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        # expect(json.dig('data', 'attributes', 'landingPage')).to eq(landing_page)
      end
    end

    context "client authorised try get diff dois landing data" do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

      it "returns with landing page results" do
        get "/dois/#{other_doi.doi}", nil, headers

        expect(json.dig("data", "attributes", "doi")).to eq(other_doi.doi)
        expect(json.dig("data", "attributes", "landingPage")).to eq(nil)
      end
    end

    context "authorised staff admin read" do
      let(:bearer) { User.generate_token(role_id: "client_admin", client_id: client.symbol.downcase) }
      let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

      it "returns with landing page results" do
        get "/dois/#{doi.doi}", nil, headers

        expect(json.dig("data", "attributes", "doi")).to eq(doi.doi)
        expect(json.dig("data", "attributes", "landingPage")).to eq(landing_page)
      end
    end
  end

  describe "GET /dois/random?prefix" do
    it "returns random doi with prefix" do
      get "/dois/random?prefix=#{prefix.uid}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to start_with("10.14454")
    end
  end

  describe "GET /dois/random?number" do
    let(:number) { 122149076 }

    it "returns predictable doi" do
      get "/dois/random?prefix=10.14454&number=#{number}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to eq("10.14454/3mfp-6m52")
    end
  end

  describe "GET /dois/DOI/get-url", vcr: true, elasticsearch: true do
    context "it works" do
      let!(:doi) { create(:doi, client: client, doi: "10.5438/fj3w-0shd", url: "https://blog.datacite.org/data-driven-development/", event: "publish") }

      before do
        import_doi_index
      end

      it "returns url" do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(json["url"]).to eq("https://blog.datacite.org/data-driven-development/")
        expect(last_response.status).to eq(200)
      end
    end

    context "no password" do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/05mb-q396", event: "publish") }

      before do
        import_doi_index
      end

      it "returns url" do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(json["url"]).to eq("https://example.org")
        expect(last_response.status).to eq(200)
      end
    end

    context "not found" do
      let!(:datacite_doi) { create(:doi, client: client, doi: "10.14454/61y1-e521", event: "publish", type: "DataciteDoi") }

      before do
        import_doi_index
      end

      it "returns not found" do
        get "/dois/#{datacite_doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"]).to eq([{ "status" => 404, "title" => "Not found" }])
      end
    end

    context "draft doi" do
      let!(:doi) { create(:doi, client: client, doi: "10.14454/61y1-e521") }

      before do
        import_doi_index
      end

      it "returns not found" do
        get "/dois/#{doi.doi}/get-url", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["url"]).to eq(doi.url)
      end
    end

    # context 'not DataCite DOI' do
    #   let(:doi) { create(:doi, client: client, doi: "10.1371/journal.pbio.2001414", event: "publish") }

    #   it 'returns nil' do
    #     get "/dois/#{doi.doi}/get-url", nil, headers

    #     expect(last_response.status).to eq(403)
    #     expect(json).to eq("errors"=>[{"status"=>403, "title"=>"SERVER NOT RESPONSIBLE FOR HANDLE"}])
    #   end
    # end
  end

  describe "GET /dois/get-dois", vcr: true do
    let!(:prefix) { create(:prefix, uid: "10.5438") }
    let!(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
    let!(:client_prefix) { create(:client_prefix, prefix: prefix, client: client) }

    it "returns all dois" do
      # 'get /dois/get-dois' uses first prefix assigned to the client.
      # The test expects the second prefix, which we defined above.
      client.prefixes.first.delete

      get "/dois/get-dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].length).to eq(449)
      expect(json["dois"].first).to eq("10.5438/0000-00SS")
    end
  end

  describe "GET /dois/get-dois no authentication", vcr: true do
    it "returns error message" do
      get "/dois/get-dois"

      expect(last_response.status).to eq(401)
      expect(json["errors"]).to eq([{ "status" => "401", "title" => "Bad credentials." }])
    end
  end
end
