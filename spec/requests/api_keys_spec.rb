# frozen_string_literal: true

require "rails_helper"

describe ApiKeysController, type: :request do
  include Passwordable

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
           headers: basic_headers,
           params: { data: { type: "api-keys", attributes: { name: "Dataverse key" } } }.to_json,
           as: :json

      expect(response).to have_http_status(:created)
      expect(json.dig("data", "attributes", "name")).to eq("Dataverse key")
      key = json.dig("data", "attributes", "key")
      expect(key).to start_with("DC.")
      expect(json.dig("data", "id")).to be_present  # uuid
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
      get "/clients/#{client.symbol}", headers: basic_headers
      expect(response).to have_http_status(:ok)
    end

    it "allows basic auth using api key as username (password discarded)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(api_key, "")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/clients/#{client.symbol}", headers: basic_headers
      expect(response).to have_http_status(:ok)
    end

    it "allows basic auth using api key as username (with dummy password, which is discarded)" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(api_key, "ignored")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/clients/#{client.symbol}", headers: basic_headers
      expect(response).to have_http_status(:ok)
    end

    it "allows Bearer with raw api key" do
      bearer_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer #{api_key}" }

      get "/clients/#{client.symbol}", headers: bearer_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /credentials/api-keys" do
    it "lists keys using Basic client credentials" do
      k = client.api_keys.create!(name: "list-test")
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      get "/credentials/api-keys", headers: basic_headers
      expect(response).to have_http_status(:ok)
      items = json["data"]
      expect(items.any? { |i| i.dig("attributes", "name") == "list-test" }).to be true
      expect(items.first.dig("attributes", "id")).to be_present
      expect(items.first.dig("attributes", "created")).to be_present
    end

    it "returns 401 without valid credentials" do
      get "/credentials/api-keys"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /credentials/api-keys/:id" do
    it "revokes the key using Basic client credentials" do
      k = client.api_keys.create!(name: "to-delete")
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "12345")
      basic_headers = { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => basic }

      delete "/credentials/api-keys/#{k.id}", headers: basic_headers
      expect(response).to have_http_status(:no_content)

      expect(k.reload.revoked_at).to be_present
    end
  end
end
