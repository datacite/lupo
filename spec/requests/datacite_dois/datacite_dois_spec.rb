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

  describe "state", prefix_pool_size: 1 do
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

  describe "PUT /dois/:id", prefix_pool_size: 1 do
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

  describe "DELETE /dois/:id", prefix_pool_size: 1 do
    let(:doi) { create(:doi, client: client, aasm_state: "draft") }

    it "returns status code 204" do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end

  describe "DELETE /dois/:id findable state", prefix_pool_size: 1 do
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }

    it "returns status code 405" do
      delete "/dois/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json["errors"]).to eq([{ "status" => "405", "title" => "Method not allowed" }])
    end
  end

  describe "POST /dois/set-url", elasticsearch: true, prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 3, client: client, url: nil) }

    it "returns dois" do
      post "/dois/set-url", nil, admin_headers

      expect(last_response.status).to eq(200)
      expect(json["message"]).to eq("Adding missing URLs queued.")
    end
  end

  describe "GET /dois/random", prefix_pool_size: 1 do
    it "returns random doi" do
      get "/dois/random?prefix=10.14454", headers: headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to start_with("10.14454")
    end
  end

  describe "GET /dois/<doi> linkcheck results", elasticsearch: true, prefix_pool_size: 2 do
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

  describe "GET /dois/random?prefix", prefix_pool_size: 1 do
    it "returns random doi with prefix" do
      get "/dois/random?prefix=#{prefix.uid}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to start_with("10.14454")
    end
  end

  describe "GET /dois/random?number", prefix_pool_size: 1 do
    let(:number) { 122149076 }

    it "returns predictable doi" do
      get "/dois/random?prefix=10.14454&number=#{number}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["dois"].first).to eq("10.14454/3mfp-6m52")
    end
  end

  describe "GET /dois/DOI/get-url", vcr: true, elasticsearch: true, prefix_pool_size: 1 do
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

  describe "GET /dois/get-dois", vcr: true, prefix_pool_size: 1 do
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

  describe "GET /dois/get-dois no authentication", vcr: true, prefix_pool_size: 1 do
    it "returns error message" do
      get "/dois/get-dois"

      expect(last_response.status).to eq(401)
      expect(json["errors"]).to eq([{ "status" => "401", "title" => "Bad credentials." }])
    end
  end

  describe "GET /dois search with license values", prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }
    let!(:dois_missing_license) do
      create_list(:doi, 3, client: client, aasm_state: "findable",
                  rights_list: [{ "rightsIdentifier" => "" }]
      )
    end

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns license values with missing when flag is set" do
      get "/dois?facets=licenses_with_missing", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "licensesWithMissing")).to be_truthy
      expect(json.dig("meta", "licensesWithMissing", 1, "id")).to eq("__missing__")
    end
  end

  describe "GET /dois search with author values", prefix_pool_size: 1 do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }
    let!(:dois_with_creators) do
      create_list(:doi, 3, client: client, aasm_state: "findable",
        creators: [
          {
            "name" => "TEST CREATOR 1",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6874",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          },
          {
            "name" => "TEST CREATOR 2",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          }
        ]
      )
    end
    let!(:dois_with_contributors) do
      create_list(:doi, 3, client: client, aasm_state: "findable",
        contributors: [
          {
            "contributorType" => "Editor",
            "name" => "TEST CONTRIBUTOR",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6876",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          }
        ]
      )
    end

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns author values" do
      get "/dois?facets=authors", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "authors")).to be_truthy
      expect(json.dig("meta", "authors").length()).to eq(3)
    end
  end

  describe "GET /dois search with funders", prefix_pool_size: 11 do
    let!(:dois_funder_1) do
      create_list(:doi, 5, aasm_state: "findable",
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

    let!(:dois_funder_2) do
      create_list(:doi, 5, aasm_state: "findable",
        funding_references: [
          { "funderName": "Fake Funders R Us: We're just in the way and should be skipped" },
          {
            "schemeUri": "https://ror.org",
            "funderName": "The French ministry of the Army, the French ministry of Ecological Transition,  the French Office for Biodiversity (OFB), the French Development Agency (AFD) and Météo France",
            "funderIdentifier": "https://ror.org/04tqhj683",
            "funderIdentifierType": "ROR"
          }
        ]
      )
    end

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns funder values" do
      get "/dois?facets=funders", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "funders")).to be_truthy
      expect(json.dig("meta", "funders").length()).to eq(2)
    end
  end

  describe "GET /dois search with person to work types multilevel", prefix_pool_size: 11 do
    let!(:dois_contributor_1) do
      create_list(:doi, 5, aasm_state: "findable",
        creators: [
          {
            "nameType" => "Personal",
            "name" => "Fenner, Martin",
            "givenName" => "Martin",
            "familyName" => "Fenner",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          }
        ],
        types: {
          "resourceTypeGeneral" => "Text"
        }
      )
    end

    let!(:dois_contributor_2) do
      create_list(:doi, 3, aasm_state: "findable",
        creators: [
          {
            "nameType" => "Personal",
            "name" => "Fenner, Martin",
            "givenName" => "Martin",
            "familyName" => "Fenner",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          }
        ],
        types: {
          "resourceTypeGeneral" => "Software"
        }
      )
    end

    let!(:dois_contributor_3) do
      create_list(:doi, 2, aasm_state: "findable",
        creators: [
          {
            "nameType" => "Personal",
            "name" => "Cousijn, Helena",
            "givenName" => "Helena",
            "familyName" => "Cousijn",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0001-6660-6214",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          }
        ],
        types: {
          "resourceTypeGeneral" => "Text"
        }
      )
    end

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns person to work types multilevel values" do
      get "/dois?facets=person_to_work_types_multilevel", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "personToWorkTypesMultilevel")).to be_truthy

      # Validate exact count of unique contributors
      expect(json.dig("meta", "personToWorkTypesMultilevel").length).to eq(2)

      # Find contributors by their ORCID IDs
      fenner = json.dig("meta", "personToWorkTypesMultilevel").find { |p| p["id"] == "https://orcid.org/0000-0003-1419-2405" }
      cousijn = json.dig("meta", "personToWorkTypesMultilevel").find { |p| p["id"] == "https://orcid.org/0000-0001-6660-6214" }

      # Validate Fenner, Martin exists with correct data
      expect(fenner).to be_present
      expect(fenner["title"]).to eq("Fenner, Martin")
      expect(fenner["count"]).to eq(8) # 5 Text + 3 Software
      expect(fenner["inner"].length).to eq(2) # Should have 2 work types

      # Validate Fenner's work types
      fenner_text = fenner["inner"].find { |wt| wt["id"] == "text" }
      fenner_software = fenner["inner"].find { |wt| wt["id"] == "software" }

      expect(fenner_text).to be_present
      expect(fenner_text["title"]).to eq("Text")
      expect(fenner_text["count"]).to eq(5)

      expect(fenner_software).to be_present
      expect(fenner_software["title"]).to eq("Software")
      expect(fenner_software["count"]).to eq(3)

      # Validate Cousijn, Helena exists with correct data
      expect(cousijn).to be_present
      expect(cousijn["title"]).to eq("Cousijn, Helena")
      expect(cousijn["count"]).to eq(2) # 2 Text
      expect(cousijn["inner"].length).to eq(1) # Should have 1 work type

      # Validate Cousijn's work types
      cousijn_text = cousijn["inner"].find { |wt| wt["id"] == "text" }

      expect(cousijn_text).to be_present
      expect(cousijn_text["title"]).to eq("Text")
      expect(cousijn_text["count"]).to eq(2)
    end
  end

  describe "GET /dois search with count values", prefix_pool_size: 1 do
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


    let!(:views) { create_list(:event_for_datacite_investigations, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-investigations-regular", total: 25) }

    let!(:downloads) { create_list(:event_for_datacite_investigations, 3, obj_id: "https://doi.org/#{doi.doi}", relation_type_id: "unique-dataset-requests-regular", total: 10) }

    before do
      clear_doi_index
      import_doi_index
    end

    it "returns citationCount, viewCount, and downloadCount in the facets" do
      get "/dois?facets=citation_count,view_count,download_count", nil, headers

      expect(last_response.status).to eq(200)

      expect(json.dig("meta", "citationCount")).to be_a(Integer)
      expect(json.dig("meta", "viewCount")).to be_a(Integer)
      expect(json.dig("meta", "downloadCount")).to be_a(Integer)

      expect(json.dig("meta", "citationCount")).to eq(12)
      expect(json.dig("meta", "viewCount")).to eq(75)
      expect(json.dig("meta", "downloadCount")).to eq(30)
    end
  end

  describe "GET /dois search with open resource values", prefix_pool_size: 2, elasticsearch: true, vcr: true do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }
    let!(:dois_other_license) do
      create_list(:doi, 3, client: client, aasm_state: "findable",
                  rights_list: [{ "rightsIdentifier" => "cc-by-2.0" }]
      )
    end
    let!(:dois_closed_license) do
      create_list(:doi, 3, client: client, aasm_state: "findable",
                  rights_list: [{ "rightsIdentifier" => "closed" }]
      )
    end

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
      clear_doi_index
      import_doi_index
    end

    it "returns contentUrlCount, openLicenses, and openLicensesCount in the facets" do
      get "/dois?facets=content_url_count,open_licenses,open_licenses_count", nil, headers

      expect(last_response.status).to eq(200)

      expect(json.dig("meta", "contentUrlCount")).to be_a(Integer)
      expect(json.dig("meta", "openLicensesCount")).to be_a(Integer)

      expect(json.dig("meta", "contentUrlCount")).to eq(0)
      expect(json.dig("meta", "openLicenses", 0, "count")).to eq(13)
      expect(json.dig("meta", "openLicensesCount")).to eq(13)
    end
  end

  describe "GET /dois/query=doi:... - CASE INSENSITIVE", vcr: true, elasticsearch: true, prefix_pool_size: 1 do
    context "it works" do
      let!(:doi) { create(:doi, client: client, doi: "10.5438/fj3w-0shd", url: "https://blog.datacite.org/data-driven-development/", event: "publish") }

      before do
        import_doi_index
      end

      it "returns DOI LOWERCASE" do
        get "/dois?query=doi:10.5438/fj3w-0shd", nil, headers
        expect(last_response.status).to eq(200)
      end

      it "returns DOI UPPERCASE" do
        get "/dois?query=doi:10.5438/FJ3W-0SHD", nil, headers
        expect(last_response.status).to eq(200)
      end

      it "returns DOI MIXED CASE" do
        get "/dois?query=doi:10.5438/Fj3W-0sHd", nil, headers
        expect(last_response.status).to eq(200)
      end
    end
  end

  describe "GET /dois/query=id:... - CASE INSENSITIVE", vcr: true, elasticsearch: true, prefix_pool_size: 1 do
    context "it works" do
      let!(:doi) { create(:doi, client: client, doi: "10.5438/fj3w-0shd", url: "https://blog.datacite.org/data-driven-development/", event: "publish") }

      before do
        import_doi_index
      end

      it "returns DOI LOWERCASE" do
        get "/dois?query=id:10.5438/fj3w-0shd", nil, headers
        expect(last_response.status).to eq(200)
      end

      it "returns DOI UPPERCASE" do
        get "/dois?query=id:10.5438/FJ3W-0SHD", nil, headers
        expect(last_response.status).to eq(200)
      end

      it "returns DOI MIXED CASE" do
        get "/dois?query=id:10.5438/Fj3W-0sHd", nil, headers
        expect(last_response.status).to eq(200)
      end
    end
  end

  ## Metadata 4.7 queries with new field: relationTypeInformation (in relatedIdentifiers and relatedItems)

  describe "GET /dois/query=...relationTypeInformation", vcr: true, elasticsearch: true, prefix_pool_size: 1 do
    let!(:datacite_doi) { create(:doi, client: client, aasm_state: "findable",
      related_items: [
        {
          "firstPage" => "250",
          "lastPage" => "264",
          "publicationYear" => "2018",
          "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044", "relatedItemIdentifierType" => "DOI" },
          "relatedItemType" => "Journal",
          "relationType" => "IsPublishedIn",
          "relationTypeInformation" => "Relates this DOI to the journal in which it was published.",
          "titles" => [{ "title" => "Physics letters / B" }],
          "volume" => "776"
        }
      ],
      related_identifiers: [
        {
          "relatedIdentifier": "10.5061/dryad.8515/1",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
          "relationTypeInformation": "Relates this DOI to the dataset in Dryad that contains the data underlying the article.",
        },
        {
          "relatedIdentifier": "10.5061/dryad.8515/2",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
        },
        {
          "relatedIdentifier": "10.1371/journal.ppat.1000446",
          "relatedIdentifierType": "DOI",
          "relationType": "IsReferencedBy",
          "relationTypeInformation": "Relates this DOI to the article that references it.",
        },
        {
          "relatedIdentifier": "10.1371/journal.ppat.1000446",
          "relatedIdentifierType": "DOI",
          "relationType": "IsSupplementTo",
        },
        {
          "relatedIdentifier": "19478877",
          "relatedIdentifierType": "PMID",
          "relationType": "IsReferencedBy",
        },
        {
          "relatedIdentifier": "19478877",
          "relatedIdentifierType": "PMID",
          "relationType": "IsSupplementTo",
        }
      ]
    )}

    before do
      clear_doi_index
      import_doi_index
    end

    it "finds the doi based on relatedItems.relationTypeInformation" do
      get "/dois?query=relatedItems.relationTypeInformation:\"Relates this DOI to*\"", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "relatedItems", 0, "relationTypeInformation")).to eq("Relates this DOI to the journal in which it was published.")
    end


    it "finds the dois based on relatedIdentiers.relationTypeInformation" do
      get "/dois?query=relatedIdentifiers.relationTypeInformation:\"Relates this DOI to*\"", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "relatedIdentifiers", 0, "relationTypeInformation")).to eq("Relates this DOI to the dataset in Dryad that contains the data underlying the article.")
      expect(json.dig("data", 0, "attributes", "relatedIdentifiers", 2, "relationTypeInformation")).to eq("Relates this DOI to the article that references it.")
    end
  end
end
