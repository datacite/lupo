# frozen_string_literal: true

require "rails_helper"

describe MediaController,
         type: :request, order: :defined, elasticsearch: true do
  let(:provider) { create(:provider, symbol: "ADMIN") }
  let(:client) { create(:client, provider: provider) }
  let(:datacite_doi) { create(:doi, client: client, type: "DataciteDoi") }
  let!(:medias) { create_list(:media, 5, doi: datacite_doi) }
  let!(:media) { create(:media, doi: datacite_doi) }
  let(:bearer) do
    User.generate_token(
      role_id: "client_admin",
      provider_id: provider.symbol.downcase,
      client_id: client.symbol.downcase,
    )
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end
  let(:media_type) { "application/xml" }
  let(:url) { "https://example.org" }

  describe "GET /v3/dois/DOI/media" do
    it "returns media" do
      get "/v3/dois/#{datacite_doi.doi}/media", nil, headers

      expect(last_response.status).to eq(200)
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(6)
      result = json["data"].first
      expect(result.dig("attributes", "mediaType")).to eq("application/json")
    end
  end

  describe "GET /v3/media query by doi not found" do
    it "returns media" do
      get "/v3/dois/xxx/media", nil, headers

      expect(json).not_to be_empty
      expect(json["errors"]).to eq(
        [
          {
            "status" => "404",
            "title" => "The resource you are looking for doesn't exist.",
          },
        ],
      )
    end

    it "returns status code 404" do
      get "/v3/dois/xxx/media", nil, headers

      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /v3/dois/DOI/media/:id" do
    context "when the record exists" do
      it "returns the media" do
        get "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
            nil, headers

        expect(json).not_to be_empty
        expect(json.dig("data", "id")).to eq(media.uid)
      end

      it "returns status code 200" do
        get "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
            nil, headers

        expect(last_response.status).to eq(200)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/v3/dois/#{datacite_doi.doi}/media/xxxx",
            nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a not found message" do
        get "/v3/dois/#{datacite_doi.doi}/media/xxxx",
            nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "POST /v3/media" do
    context "when the request is valid" do
      let(:media_type) { "application/xml" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes" => { "mediaType" => media_type, "url" => url },
          },
        }
      end

      it "creates a media record" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(json.dig("data", "attributes", "mediaType")).to eq(media_type)
        expect(json.dig("data", "attributes", "url")).to eq(url)
      end

      it "returns status code 201" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(last_response.status).to eq(201)
      end
    end

    context "when the mediaType is missing" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes" => { "mediaType" => nil, "url" => url },
          },
        }
      end

      it "returns status code 201" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(last_response.status).to eq(201)
      end

      it "creates a media record" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(json.dig("data", "attributes", "url")).to eq(url)
      end
    end

    context "when the media_type is not valid" do
      let(:media_type) { "text" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes" => { "mediaType" => media_type, "url" => url },
            "relationships" => {
              "doi" => {
                "data" => { "type" => "dois", "id" => datacite_doi.doi },
              },
            },
          },
        }
      end

      it "returns status code 422" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(last_response.status).to eq(422)
      end

      it "returns a validation failure message" do
        post "/v3/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(json["errors"]).to eq(
          [{ "source" => "media_type", "title" => "Is invalid" }],
        )
      end
    end
  end

  describe "PATCH /v3/dois/DOI/media/:id" do
    context "when the request is valid" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes" => { "mediaType" => media_type, "url" => url },
            "relationships" => {
              "doi" => {
                "data" => { "type" => "dois", "id" => datacite_doi.doi },
              },
            },
          },
        }
      end

      it "updates the record" do
        patch "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
              valid_attributes, headers

        expect(json.dig("data", "attributes", "mediaType")).to eq(media_type)
        expect(json.dig("data", "attributes", "url")).to eq(url)
        expect(json.dig("data", "attributes", "version")).to be > 0
      end

      it "returns status code 200" do
        patch "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
              valid_attributes, headers

        expect(last_response.status).to eq(200)
      end
    end

    context "when the request is invalid" do
      let(:url) { "mailto:info@example.org" }
      let(:params) do
        {
          "data" => {
            "type" => "media",
            "attributes" => { "mediaType" => media_type, "url" => url },
            "relationships" => {
              "doi" => {
                "data" => { "type" => "dois", "id" => datacite_doi.doi },
              },
            },
          },
        }
      end

      it "returns status code 422" do
        patch "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
              params, headers

        expect(last_response.status).to eq(422)
      end

      it "returns a validation failure message" do
        patch "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
              params, headers

        expect(json["errors"].first).to eq(
          "source" => "url", "title" => "Is invalid",
        )
      end
    end
  end

  describe "DELETE /v3/dois/DOI/media/:id" do
    context "when the resources does exist" do
      it "returns status code 204" do
        delete "/v3/dois/#{datacite_doi.doi}/media/#{media.uid}",
               nil, headers

        expect(last_response.status).to eq(204)
      end
    end

    context "when the resources doesnt exist" do
      it "returns status code 404" do
        delete "/v3/dois/#{datacite_doi.doi}/media/xxx",
               nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/v3/dois/#{datacite_doi.doi}/media/xxx",
               nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end
end
