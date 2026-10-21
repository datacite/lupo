# frozen_string_literal: true

require "rails_helper"
include Passwordable

DEFAULT_DOIS_FACETS = [
  "states",
  "resourceTypes",
  "created",
  "published",
  "registered",
  "providers",
  "clients",
  "affiliations",
  "prefixes",
  "certificates",
  "licenses",
  "schemaVersions",
  "linkChecksStatus",
  "subjects",
  "fieldsOfScience",
  "citations",
  "views",
  "downloads"
]

DEFAULT_META_FIELDS = [
  "total",
  "totalPages",
  "page",
]

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
      json["data"].each do |doi|
        expect(doi.dig("attributes", "xml")).not_to be_present
      end
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
      expect(next_link).to start_with("/dois?")
      expect(next_link).not_to include("disable-facets=")
      expect(next_link).to include("page%5Bnumber%5D=2")
      expect(next_link).to include("page%5Bsize%5D=4")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to start_with("/dois?")
      expect(next_link).not_to include("disable-facets=")
      expect(next_link).to include("page%5Bnumber%5D=3")
      expect(next_link).to include("page%5Bsize%5D=4")

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
      expect(next_link).to start_with("/dois?")
      expect(next_link).not_to include("disable-facets=")
      expect(next_link).to include("page%5Bnumber%5D=2")
      expect(next_link).to include("page%5Bsize%5D=5")

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

    it "returns an error when cursor and random are used together" do
      get "/dois?page[cursor]=1&page[size]=4&random=true", nil, headers

      expect(last_response.status).to eq(400)
      expect(json["errors"].first["title"]).to eq("Cursor-based pagination and random sampling are mutually exclusive, please choose one or the other.")
    end

    xit "returns dois with random query" do
      # Set specific seed
      srand(1234)
      get "/dois?random=true&page[size]=1", nil, headers
      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      first_doi = json.dig("data", 0, "id")

      # Change the seed
      srand(5678)
      get "/dois?random=true&page[size]=1", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", 0, "id")).not_to eq(first_doi)
    end

    it "ignores random query when value is different from true" do
      srand(1234)
      get "/dois?random=false&page[size]=1", nil, headers
      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      first_doi = json.dig("data", 0, "id")

      # Change the seed
      srand(5678)
      get "/dois?random=false&page[size]=1", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", 0, "id")).to eq(first_doi)
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
        expect(doi.dig("attributes", "xml")).to be_present
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
      expect(next_link).to start_with("/dois?")
      expect(next_link).not_to include("disable-facets=")
      expect(next_link).to include("fields%5Bdois%5D=id")
      expect(next_link).to include("page%5Bnumber%5D=2")
      expect(next_link).to include("page%5Bsize%5D=2")

      get "/dois?fields[dois]=id,subjects&page[size]=2&page[number]=1", nil, headers

      expect(last_response.status).to eq(200)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to start_with("/dois?")
      expect(next_link).not_to include("disable-facets=")
      expect(next_link).to include("fields%5Bdois%5D=id%2Csubjects")
      expect(next_link).to include("page%5Bnumber%5D=2")
      expect(next_link).to include("page%5Bsize%5D=2")
    end

    it "returns default facets" do
      get "/dois", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)

      expect(json.dig("meta").length).to eq(DEFAULT_DOIS_FACETS.length + 3)
      expect(json.dig("meta").keys).to match_array(DEFAULT_DOIS_FACETS + DEFAULT_META_FIELDS)
    end

    it "returns default facets when disable-facets is set to false" do
      get "/dois?disable-facets=false", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)

      expect(json.dig("meta").length).to eq(DEFAULT_DOIS_FACETS.length + 3)
      expect(json.dig("meta").keys).to match_array(DEFAULT_DOIS_FACETS + DEFAULT_META_FIELDS)
    end

    it "returns no facets when disable-facets is set to true" do
      get "/dois?disable-facets=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta").length).to eq(3)
      DEFAULT_DOIS_FACETS.each do |facet|
        expect(json.dig("meta", facet)).to eq(nil)
      end
    end

    it "includes disable-facets=false in pagination next link when param is passed" do
      get "/dois?page[number]=1&page[size]=4&disable-facets=false", nil, headers

      expect(last_response.status).to eq(200)
      next_link = json.dig("links", "next")
      expect(next_link).to be_present
      expect(next_link).to include("disable-facets=false")
    end

    it "includes disable-facets=true in pagination next link when param is passed" do
      get "/dois?page[number]=1&page[size]=4&disable-facets=true", nil, headers

      expect(last_response.status).to eq(200)
      next_link = json.dig("links", "next")
      expect(next_link).to be_present
      expect(next_link).to include("disable-facets=true")
    end

    it "returns no facets when facets is empty" do
      get "/dois?facets=", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta").length).to eq(3)
      DEFAULT_DOIS_FACETS.each do |facet|
        expect(json.dig("meta", facet)).to eq(nil)
      end
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

    it "returns no facets when the result set is empty" do
      get "/dois?query=creators.name:foo", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(0)
      expect(json.dig("meta", "total")).to eq(0)
      expect(json.dig("meta").length).to eq(3)
      expect(json.dig("meta").keys).to match_array(DEFAULT_META_FIELDS)
    end

    describe "GET /dois with DISABLE_FACETS_BY_DEFAULT=true" do
      around do |example|
        orig = ENV["DISABLE_FACETS_BY_DEFAULT"]
        ENV["DISABLE_FACETS_BY_DEFAULT"] = "true"
        example.run
      ensure
        ENV["DISABLE_FACETS_BY_DEFAULT"] = orig
      end

      it "returns no facets by default when env is set" do
        get "/dois", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(10)
        expect(json.dig("meta", "total")).to eq(10)
        expect(json.dig("meta").length).to eq(3)
        DEFAULT_DOIS_FACETS.each do |facet|
          expect(json.dig("meta", facet)).to eq(nil)
        end
      end

      it "returns default facets when disable-facets=false overrides env" do
        get "/dois?disable-facets=false", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(10)
        expect(json.dig("meta", "total")).to eq(10)
        expect(json.dig("meta").length).to eq(DEFAULT_DOIS_FACETS.length + 3)
        expect(json.dig("meta").keys).to match_array(DEFAULT_DOIS_FACETS + DEFAULT_META_FIELDS)
      end

      it "omits disable-facets from pagination next link when param not passed (even when env set)" do
        get "/dois?page[number]=1&page[size]=4", nil, headers

        expect(last_response.status).to eq(200)
        next_link = json.dig("links", "next")
        expect(next_link).to be_present
        expect(next_link).not_to include("disable-facets=")
      end
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

  describe "GET /dois with funded_by filter", prefix_pool_size: 3 do
    include_context "ROR funding stubs for DOI indexing"

    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable", version_info: "testtag") }
    let!(:funded_by_ec_dois) do
      create_list(:doi, 5, client: client, aasm_state: "findable", funding_references:
        [
          {
            "awardUri": "info:eu-repo/grantAgreement/EC/FP7/282625/",
            "awardTitle": "MOTivational strength of ecosystem services and alternative ways to express the value of BIOdiversity",
            "funderName": "European Commission",
            "awardNumber": "282625",
            "funderIdentifier": "https://doi.org/10.13039/501100000780",
            "funderIdentifierType": "Crossref Funder ID"
          }
      ])
    end

    let!(:funded_by_ec_crossref_funder_id_descendant_dois) do
      create_list(:doi, 2, client: client, aasm_state: "findable", funding_references:
        [
          {
            "awardUri": "info:eu-repo/grantAgreement/EC/FP7/282625/",
            "awardTitle": "MOTivational strength of ecosystem services and alternative ways to express the value of BIOdiversity",
            "funderName": "European Commission",
            "awardNumber": "282625",
            "funderIdentifier": "https://doi.org/10.13039/501100000781",
            "funderIdentifierType": "Crossref Funder ID"
          }
      ])
    end
    let!(:funded_by_ec_ror_descendant_dois) do
      create_list(:doi, 4, client: client, aasm_state: "findable", funding_references:
        [
          {
            "awardUri": "info:eu-repo/grantAgreement/EC/FP7/282625/",
            "awardTitle": "MOTivational strength of ecosystem services and alternative ways to express the value of BIOdiversity",
            "funderName": "European Commission",
            "awardNumber": "282625",
            "funderIdentifier": "ror.org/05mkt9r11",
            "funderIdentifierType": "ROR"
          }
      ])
    end
    let!(:funded_by_lshtm_dois) do
      create_list(:doi, 2, client: client, aasm_state: "findable", funding_references:
        [
          {
            "awardUri": "info:eu-repo/grantAgreement/EC/FP7/284382/",
            "awardTitle": "Institutionalizing global genetic-resource commons. Global Strategies for accessing and using essential public knowledge assets in the life sciences.",
            "funderName": "London School of Hygiene & Tropical Medicine",
            "awardNumber": "284382",
            "funderIdentifier": "https://ror.org/00a0jsq62",
            "funderIdentifierType": "ROR"
          }
      ])
    end

    before do
      clear_doi_index
      import_doi_index
    end

    it "filters by funder when funded_by is set with Crossref Funder ID funderIdentifier", vcr: true do
      get "/dois?funded-by=https://ror.org/00k4n6c32", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
    end

    it "filters by funder when query string is set with Crossref Funder ID funderIdentifier", vcr: true do
      get "/dois?query=funder_rors:\"https://ror.org/00k4n6c32\"", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
    end

    it "filters by funder when funded_by is set with ROR funderIdentifier", vcr: true do
      get "/dois?funded-by=https://ror.org/00a0jsq62", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_lshtm_dois.first.doi.downcase)
    end

    it "filters by funder and funder child orgs when funded_by is set with Crossref Funder ID funderIdentifier and include_funder_child_organizations is true", vcr: true do
      get "/dois?funded-by=https://ror.org/00k4n6c32&include-funder-child-organizations=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(11)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_crossref_funder_id_descendant_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_ror_descendant_dois.first.doi.downcase)
    end

    it "filters by funder and funder child orgs when query string is set with Crossref Funder ID funderIdentifier and child organizations are included", vcr: true do
      get "/dois?query=funder_rors:\"https://ror.org/00k4n6c32\" OR funder_parent_rors:\"https://ror.org/00k4n6c32\"", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(11)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_crossref_funder_id_descendant_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_ror_descendant_dois.first.doi.downcase)
    end

    it "filters by funder when entered ROR is a parent of entered RORs or Crossref Funder IDs but isn't included in metadata", vcr: true do
      get "/dois?funded-by=https://ror.org/019w4f821&include-funder-child-organizations=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(11)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_crossref_funder_id_descendant_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_ror_descendant_dois.first.doi.downcase)
    end

    it "filters by funder when entered ROR in query is a parent of entered RORs or Crossref Funder IDs but isn't included in metadata", vcr: true do
      get "/dois?query=funder_rors:\"https://ror.org/019w4f821\" OR funder_parent_rors:\"https://ror.org/019w4f821\"", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(11)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_crossref_funder_id_descendant_dois.first.doi.downcase)
      expect(json["data"].map { |d| d["attributes"]["doi"] }).to include(funded_by_ec_ror_descendant_dois.first.doi.downcase)
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

  describe "GET /dois/:id", elasticsearch: true, prefix_pool_size: 1 do
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
end
