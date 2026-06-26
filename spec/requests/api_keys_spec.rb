# frozen_string_literal: true

require "rails_helper"

describe ApiKeysController, type: :request do
  include Passwordable

  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) do
    Client.generate_token(
      role_id: "staff_admin",
      uid: admin.symbol,
      password: admin.password,
    )
  end
  let(:admin_headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer,
    }
  end

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: "DATACITE.TESTKEY", password_input: "12345") }
  let(:bearer) do
    Client.generate_token(
      role_id: "client_admin",
      uid: client.symbol.downcase,
      provider_id: provider.symbol.downcase,
      client_id: client.symbol.downcase,
    )
  end
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "POST /credentials/api-keys" do
    it "creates an api key using Basic client credentials (infers client from auth)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      post "/credentials/api-keys",
           { data: { type: "api-keys", attributes: { name: "Dataverse key" } } },
           basic_headers

      expect(last_response.status).to eq(201)
      expect(json.dig("data", "attributes", "name")).to eq("Dataverse key")
      key = json.dig("data", "attributes", "key")
      expect(key).to start_with("DC.")
      expect(json.dig("data", "id")).to be_present  # uuid
      expect(json.dig("data", "relationships", "client", "data", "id")).to eq(
        client.symbol,
      )
      expect(json.dig("data", "relationships", "client", "data", "type")).to eq(
        "clients",
      )
    end
  end

  describe "authentication with api key (drop-in)" do
    let(:api_key) do
      # create via direct model to avoid controller for this test
      k = client.api_keys.create!(name: "auth-test")
      k.key
    end

    it "allows basic auth using client symbol + api key value (as password)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, api_key)
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      # hit an authenticated endpoint that returns 200 for client
      get "/clients/#{client.symbol}",
          nil, basic_headers
      expect(last_response.status).to eq(200)
    end

    it "allows basic auth using api key as username (password discarded)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(api_key, "")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/clients/#{client.symbol}",
          nil, basic_headers
      expect(last_response.status).to eq(200)
    end

    it "allows basic auth using api key as username (with dummy password, which is discarded)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(api_key, "ignored")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/clients/#{client.symbol}",
          nil, basic_headers
      expect(last_response.status).to eq(200)
    end

    it "allows Bearer with raw api key" do
      bearer_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer #{api_key}" }

      get "/clients/#{client.symbol}",
          nil, bearer_headers
      expect(last_response.status).to eq(200)
    end
  end

  describe "GET /credentials/api-keys" do
    it "lists keys using Basic client credentials" do
      client.api_keys.create!(name: "list-test")
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/credentials/api-keys",
          nil, basic_headers
      expect(last_response.status).to eq(200)
      items = json["data"]
      expect(items.any? { |i| i.dig("attributes", "name") == "list-test" }).to be true
      expect(items.first["id"]).to be_present
      expect(items.first.dig("attributes", "created")).to be_present
    end

    it "includes revoked keys when requested by an admin" do
      active_key = client.api_keys.create!(name: "active-key")
      revoked_key = client.api_keys.create!(name: "revoked-key")
      revoked_key.revoke!

      get "/credentials/api-keys?include_revoked=true",
          nil, admin_headers

      expect(last_response.status).to eq(200)
      items = json["data"]

      expect(items.map { |item| item.dig("attributes", "name") }).to include("active-key", "revoked-key")
      expect(items.find { |item| item.dig("attributes", "name") == "revoked-key" }.dig("attributes", "revokedAt")).to be_present
      expect(items.find { |item| item.dig("attributes", "name") == "active-key" }.dig("attributes", "revokedAt")).to be_nil
      expect(active_key.reload.revoked_at).to be_nil
    end

    it "includes own revoked keys for client password when include_revoked=true" do
      client.api_keys.create!(name: "active-key")
      revoked_key = client.api_keys.create!(name: "revoked-key")
      revoked_key.revoke!

      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/credentials/api-keys?include_revoked=true", nil, basic_headers

      expect(last_response.status).to eq(200)
      names = json["data"].map { |item| item.dig("attributes", "name") }
      expect(names).to include("active-key", "revoked-key")
    end

    it "returns 403 for provider credentials (no client_id)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(provider.symbol, "12345")
      # provider factory may not set password — use token instead if needed
      provider_token = Client.generate_token(
        role_id: "provider_admin",
        uid: provider.symbol.downcase,
        provider_id: provider.symbol.downcase,
      )
      get "/credentials/api-keys",
          nil,
          {
            "HTTP_ACCEPT" => "application/vnd.api+json",
            "HTTP_AUTHORIZATION" => "Bearer #{provider_token}",
          }
      expect(last_response.status).to eq(403)
    end

    it "returns 401 without valid credentials" do
      get "/credentials/api-keys",
          nil
      expect(last_response.status).to eq(401)
    end
  end

  describe "DELETE /credentials/api-keys/:id" do
    it "revokes the key using Basic client credentials" do
      k = client.api_keys.create!(name: "to-delete")
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      delete "/credentials/api-keys/#{k.id}",
             nil, basic_headers
      expect(last_response.status).to eq(204)

      expect(k.reload.revoked_at).to be_present
    end
  end

  describe "API key cannot manage credentials" do
    let(:api_key_record) { client.api_keys.create!(name: "machine") }
    let(:plain_key) { api_key_record.key }
    let(:other_key) { client.api_keys.create!(name: "other") }

    it "rejects list with API key as Bearer" do
      get "/credentials/api-keys",
          nil,
          {
            "HTTP_ACCEPT" => "application/vnd.api+json",
            "HTTP_AUTHORIZATION" => "Bearer #{plain_key}",
          }
      expect(last_response.status).to eq(403)
    end

    it "rejects create with API key as Basic username" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(plain_key, "")
      post "/credentials/api-keys",
           { data: { type: "api-keys", attributes: { name: "sibling" } } },
           { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }
      expect(last_response.status).to eq(403)
      expect(client.api_keys.where(name: "sibling")).to be_empty
    end

    it "rejects create with client symbol + API key as password" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, plain_key)
      post "/credentials/api-keys",
           { data: { type: "api-keys", attributes: { name: "sibling" } } },
           { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }
      expect(last_response.status).to eq(403)
    end

    it "rejects revoke with API key Bearer" do
      delete "/credentials/api-keys/#{other_key.id}",
             nil,
             {
               "HTTP_ACCEPT" => "application/vnd.api+json",
               "HTTP_AUTHORIZATION" => "Bearer #{plain_key}",
             }
      expect(last_response.status).to eq(403)
      expect(other_key.reload.revoked_at).to be_nil
    end

    it "still allows DOI/client API with API key Bearer" do
      get "/clients/#{client.symbol}",
          nil,
          {
            "HTTP_ACCEPT" => "application/vnd.api+json",
            "HTTP_AUTHORIZATION" => "Bearer #{plain_key}",
          }
      expect(last_response.status).to eq(200)
    end

    it "allows credential management with JWT (password session)" do
      get "/credentials/api-keys", nil, headers
      expect(last_response.status).to eq(200)
    end

    it "rejects list with JWT that has client_api role (no ApiKey ability)" do
      api_jwt = Client.generate_token(
        role_id: "client_api",
        uid: client.symbol.downcase,
        provider_id: provider.symbol.downcase,
        client_id: client.symbol.downcase,
      )
      get "/credentials/api-keys",
          nil,
          {
            "HTTP_ACCEPT" => "application/vnd.api+json",
            "HTTP_AUTHORIZATION" => "Bearer #{api_jwt}",
          }
      expect(last_response.status).to eq(403)
    end
  end

  describe "POST /token rejects API key credentials" do
    it "does not mint a token when password is an API key" do
      api_key = client.api_keys.create!(name: "no-token")
      params =
        "grant_type=password&username=#{client.symbol}&password=#{CGI.escape(api_key.key)}"
      post "/token", params

      expect(last_response.status).to eq(400)
      expect(json.fetch("errors", {}).first["title"]).to eq(
        "Wrong account ID or password.",
      )
      expect(json["access_token"]).to be_blank
    end

    it "mints a token with the real client password" do
      params = "grant_type=password&username=#{client.symbol}&password=12345"
      post "/token", params

      expect(last_response.status).to eq(200)
      expect(json["access_token"]).to be_present
    end
  end
end
