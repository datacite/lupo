# frozen_string_literal: true

require "rails_helper"

describe ClientsController, type: :request, elasticsearch: true do
  let(:ids) { clients.map(&:uid).join(",") }
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
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
            "data": { "type": "providers", "id": provider.symbol.downcase },
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
      sleep 1
    end

    it "returns clients" do
      get "/clients", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(4)
    end
  end

  # # Test suite for GET /clients
  # describe 'GET /clients query' do
  #   before { get "/clients?query=#{query}", headers: headers }
  #
  #   it 'returns clients' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(11)
  #   end
  #
  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  # describe 'GET /clients?ids=', elasticsearch: true do
  #   before do
  #     sleep 1
  #     get "/clients?ids=#{ids}", headers: headers
  #   end

  #   it 'returns clients' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(10)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

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
    let(:client) { create(:client) }
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
      it "creates a client" do
        post "/clients", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["contactEmail"]).to eq("bob@example.com")
        expect(attributes["clientType"]).to eq("repository")

        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.symbol.downcase,
        )

        Client.import
        sleep 2

        get "/clients", nil, headers

        expect(json["data"].size).to eq(2)
        expect(json.dig("meta", "clientTypes")).to eq(
          [{ "count" => 2, "id" => "repository", "title" => "Repository" }],
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
                "data": { "type": "providers", "id": provider.symbol.downcase },
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
            { "source" => "system_email", "title" => "Can't be blank" },
            { "source" => "system_email", "title" => "Is invalid" },
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

    context "transfer repository" do
      let(:new_provider) do
        create(:provider, symbol: "QUECHUA", password_input: "12345")
      end
      let!(:prefixes) { create_list(:prefix, 3) }
      let!(:prefix) { prefixes.first }
      let!(:provider_prefix_more) do
        create(:provider_prefix, provider: provider, prefix: prefixes.last)
      end
      let!(:provider_prefix) do
        create(:provider_prefix, provider: provider, prefix: prefix)
      end
      let!(:client_prefix) do
        create(
          :client_prefix,
          client: client,
          prefix: prefix,
          provider_prefix_id: provider_prefix.uid,
        )
      end
      let(:doi) { create_list(:doi, 10, client: client) }
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "mode" => "transfer", "targetId" => new_provider.symbol
            },
          },
        }
      end

      before do
        ProviderPrefix.import
        sleep 3
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("My data center")
        expect(
          json.dig("data", "relationships", "provider", "data", "id"),
        ).to eq("quechua")
        expect(
          json.dig("data", "relationships", "prefixes", "data").first.dig("id"),
        ).to eq(prefix.uid)

        get "/providers/#{provider.symbol}"

        expect(
          json.dig("data", "relationships", "prefixes", "data").length,
        ).to eq(1)
        expect(
          json.dig("data", "relationships", "prefixes", "data").first.dig("id"),
        ).to eq(prefixes.last.uid)

        get "/providers/#{new_provider.symbol}"
        expect(
          json.dig("data", "relationships", "prefixes", "data").first.dig("id"),
        ).to eq(prefix.uid)

        get "/prefixes/#{prefix.uid}"
        expect(
          json.dig("data", "relationships", "clients", "data").first.dig("id"),
        ).to eq(client.symbol.downcase)

        get "provider-prefixes?query=#{prefix.uid}"
        expect(
          json.dig("meta", "total"),
        ).to eq(1)
        expect(
          json.dig("data").first.dig("relationships", "provider", "data", "id"),
        ).to eq("quechua")
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
        )
      end
    end

    context "using basic auth", vcr: true do
      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => { "name" => "Imperial College 2" },
          },
        }
      end
      let(:credentials) do
        provider.encode_auth_param(
          username: provider.symbol.downcase, password: "12345",
        )
      end
      let(:headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Basic " + credentials,
        }
      end

      it "updates the record" do
        put "/clients/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Imperial College 2",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
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

    # it "transfered all DOIs" do
    #   expect(Doi.query(nil, client_id: client.symbol.downcase).results.total).to eq(0)
    #   expect(Doi.query(nil, client_id: target.symbol.downcase).results.total).to eq(3)
    # end
  end
end
