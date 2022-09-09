# frozen_string_literal: true

require "rails_helper"

describe "Client Prefixes", type: :request, elasticsearch: true do
  let!(:provider) { create(:provider) }
  let!(:client) { create(:client, provider: provider) }
  let!(:client_prefix) { client.client_prefixes.first }
  let!(:provider_prefix) { client.provider_prefixes.first }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end

  describe "GET /client-prefixes" do
    before do
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    it "returns client-prefixes" do
      get "/client-prefixes", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
    end
  end

  describe "GET /client-prefixes/:uid" do
    before do
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    context "when the record exists" do
      it "returns the client-prefix" do
        get "/client-prefixes/#{client_prefix.uid}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(client_prefix.uid)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/client-prefixes/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "PATCH /client-prefixes/:uid" do
    it "returns method not supported error" do
      patch "/client-prefixes/#{client_prefix.uid}",
            nil, headers

      expect(last_response.status).to eq(405)
      expect(json.dig("errors")).to eq(
        [{ "status" => "405", "title" => "Method not allowed" }],
      )
    end
  end

  describe "POST /client-prefixes" do
    context "when the request is valid" do
      # A valid request depends on having a valid, unassigned provider_prefix.
      # A valid provider prefix: created from an available prefix, that has not yet been assigned to a repository.
      let!(:prefix) { create(:prefix, uid: "10.7000") }
      let!(:provider_prefix) do
        create(:provider_prefix, provider: provider, prefix: prefix)
      end

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "client-prefixes",
            "relationships": {
              "client": {
                "data": { "type": "client", "id": client.symbol.downcase },
              },
              "providerPrefix": {
                "data": { "type": "provider-prefix", "id": provider_prefix.uid },
              },
              "prefix": { "data": { "type": "prefix", "id": prefix.uid } },
            },
          },
        }
      end

      it "creates a client-prefix" do
        post "/client-prefixes", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "id")).not_to be_nil
      end
    end

    context "when the request is invalid" do
      let!(:client) { create(:client) }
      let(:not_valid_attributes) do
        { "data" => { "type" => "client-prefixes" } }
      end

      it "returns status code 422" do
        post "/client-prefixes", not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "client", "title" => "Must exist",
        )
      end
    end
  end

  describe "DELETE /client-prefixes/:uid" do
    it "deletes the prefix" do
      delete "/client-prefixes/#{client_prefix.uid}",
             nil, headers
      expect(last_response.status).to eq(204)
    end
  end
end
