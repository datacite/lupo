# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe ClientsController, type: :request, elasticsearch: true do
  let(:ids) { clients.map(&:uid).join(",") }
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
  let(:provider_member_only) { create(:provider, role_name: "ROLE_MEMBER", symbol: "YYYY", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let!(:client) { create(:client, provider: provider) }
  let(:params) do
    {
      "data" => {
        "type" => "clients",
        "attributes" => {
          "symbol" => provider.symbol + ".IMPERIAL",
          "name" => "Imperial College",
          "contactEmail" => "bob@example.com",
          "clientType" => "repository",
        },
        "relationships": {
          "provider": {
            "data": { "type": "providers", "id": provider.uid },
          },
        },
      },
    }
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end
  let(:query) { "jamon" }

  describe "GET /clients", elasticsearch: true do
    let!(:clients) { create_list(:client, 3) }

    before do
      Client.import
      Provider.import
      sleep 1
    end

    it "returns clients" do
      get "/clients", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(4)
    end
  end

  describe "GET /clients/:id" do
    context "when the record exists" do
      it "returns the client" do
        get "/clients/#{client.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(client.name)
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "bc7d0274-3472-4a79-b631-e4c7baccc667",
        )
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/clients/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "GET /clients/totals" do
    let!(:client) { create(:client, provider: provider) }
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end

    before do
      Client.import
      DataciteDoi.import
      sleep 3
    end

    it "returns clients" do
      get "/clients/totals", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.first.dig("count")).to eq(3)
      expect(json.first.dig("states")).to eq(
        [{ "count" => 3, "id" => "findable", "title" => "Findable" }],
      )
      expect(json.first.dig("temporal")).not_to be_nil
    end
  end

  describe "POST /clients" do
    context "when the request is valid" do
      let(:params_igsn_catalog) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "symbol" => provider.symbol + ".IGSN",
              "name" => "Imperial College",
              "contactEmail" => "bob@example.com",
              "clientType" => "igsnCatalog",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider.uid },
              },
            },
          },
        }
      end

      let(:raid_registry_client_id) { provider.symbol + ".RAID" }
      let(:params_raid_registry) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "symbol" => raid_registry_client_id,
              "name" => "Imperial College",
              "contactEmail" => "bob@example.com",
              "clientType" => "raidRegistry",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider.uid },
              },
            },
          },
        }
      end

      it "creates a client" do
        post "/clients", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["contactEmail"]).to eq("bob@example.com")
        expect(attributes["clientType"]).to eq("repository")

        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )

        Client.import
        sleep 2

        get "/clients", nil, headers

        expect(json["data"].size).to eq(2)
        expect(json.dig("meta", "clientTypes")).to eq(
          [{ "count" => 2, "id" => "repository", "title" => "Repository" }],
        )
      end

      it "creates a client with igsnCatalog client_type" do
        post "/clients", params_igsn_catalog, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["clientType"]).to eq("igsnCatalog")

        Client.import
        sleep 2

        get "/clients", nil, headers

        expect(json["data"].size).to eq(2)
        expect(json.dig("meta", "clientTypes").find { |clientTypeAgg| clientTypeAgg["id"] == "igsnCatalog" }).to eq(
          { "count" => 1, "id" => "igsnCatalog", "title" => "IGSN ID Catalog" },
        )
      end

      it "creates a client with raidRegistry client_type" do
        post "/clients", params_raid_registry, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["clientType"]).to eq("raidRegistry")

        Client.import
        sleep 2

        get "/clients", nil, headers

        expect(json["data"].size).to eq(2)
        raid_registry_client = json.dig("data").find { |client| client.dig("attributes", "clientType") == "raidRegistry" }
        expect(raid_registry_client.dig("attributes", "symbol")).to eq(raid_registry_client_id)
        expect(json.dig("meta", "clientTypes").find { |clientTypeAgg| clientTypeAgg["id"] == "raidRegistry" }).to eq(
          { "count" => 1, "id" => "raidRegistry", "title" => "RAiD Registry" },
        )
      end
    end

    context "when the request is invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "symbol" => provider.symbol + ".IMPERIAL",
              "name" => "Imperial College",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider.uid },
              },
            },
          },
        }
      end

      let(:provider_member_only_basic_auth_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(provider_member_only.symbol, ENV["MDS_PASSWORD"]) } }
      let(:params_member_only) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "symbol" => provider_member_only.symbol + ".IMPERIAL",
              "name" => "Imperial College",
              "contactEmail" => "bob@example.com",
              "clientType" => "repository",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider_member_only.uid },
              },
            },
          },
        }
      end

      it "returns status code 422" do
        post "/clients", params, headers

        expect(last_response.status).to eq(422)
      end

      it "returns a validation failure message" do
        post "/clients", params, headers

        expect(json["errors"]).to eq(
          [
            {
              "source" => "system_email",
              "title" => "Can't be blank",
              "uid" => provider.uid + ".imperial"
            },
          ],
        )
      end

      it "returns status code 422" do
        post "/clients", params_member_only, provider_member_only_basic_auth_headers

        expect(last_response.status).to eq(403)
      end
    end
  end

  describe "POST /clients" do
    context "when there are available prefixes" do
      it "creates a client with a prefix from the pool" do
        post "/clients", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["contactEmail"]).to eq("bob@example.com")
        expect(attributes["clientType"]).to eq("repository")
        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )

        prefixes = json.dig("data", "relationships", "prefixes", "data")
        expect(prefixes.count).to eq(1)
        expect(prefixes.first["id"]).to eq(@prefix_pool[1].uid)
      end
    end

    context "when there are available provider prefixes" do
      let!(:prefix) { create(:prefix, uid: "10.14454") }
      let!(:provider_prefix) do
        create(:provider_prefix, provider: provider, prefix: prefix)
      end

      it "creates a client with a provider prefix" do
        post "/clients", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["contactEmail"]).to eq("bob@example.com")
        expect(attributes["clientType"]).to eq("repository")
        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )

        prefixes = json.dig("data", "relationships", "prefixes", "data")
        expect(prefixes.count).to eq(1)
        expect(prefixes.first["id"]).to eq("10.14454")
      end
    end

    context "when there are no available prefixes" do
      it "returns error message", prefix_pool_size: 1 do
        post "/clients", params, headers

        expect(json["errors"]).to eq(
          [
            {
              "source" => "base",
              "title" => "No prefixes available.  Unable to create repository.",
              "uid" => params["data"]["attributes"]["symbol"].downcase
            },
          ],
        )
      end
    end
  end

  describe "PUT /clients/:id" do
    context "when the record exists" do
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "name" => "Imperial College 2",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
            },
          },
        }
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Imperial College 2",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
      end
    end

    context "change client_type" do
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => { "clientType" => "periodical" },
          },
        }
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "clientType")).to eq("periodical")
      end
    end

    context "removes the globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "clients", "attributes" => { "globusUuid" => nil }
          },
        }
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("My data center")
        expect(json.dig("data", "attributes", "globusUuid")).to be_nil
      end
    end

    context "invalid globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "clients", "attributes" => { "globusUuid" => "abc" }
          },
        }
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "globus_uuid", "title" => "Abc is not a valid UUID",
          "uid" => client.uid
        )
      end
    end

    context "when the request is invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "symbol" => client.symbol + "M",
              "email" => "bob@example.com",
              "name" => "Imperial College",
            },
          },
        }
      end

      it "returns a validation failure message" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "symbol", "title" => "Cannot be changed",
          "uid" => client.uid + "m"
        )
      end
    end
  end

  describe "DELETE /clients/:id" do
    it "returns status code 204" do
      delete "/clients/#{client.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end

    context "when the resource doesnt exist" do
      it "returns status code 404" do
        delete "/clients/xxx", nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/clients/xxx", nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "doi transfer", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client) }
    let(:target) do
      create(
        :client,
        provider: provider,
        symbol: provider.symbol + ".TARGET",
        name: "Target Client",
      )
    end
    let(:params) do
      {
        "data" => {
          "type" => "clients", "attributes" => { "targetId" => target.symbol }
        },
      }
    end

    before do
      DataciteDoi.import
      sleep 2
    end

    it "returns status code 200" do
      put "/clients/#{client.symbol}", params, headers
      sleep 1

      expect(last_response.status).to eq(200)
    end
  end
end
