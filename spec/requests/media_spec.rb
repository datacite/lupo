# frozen_string_literal: true

require "rails_helper"

describe MediaController,
         type: :request, order: :defined, elasticsearch: true do
  let!(:provider) { create(:provider, symbol: "ADMIN") }
  let!(:prefix) { create(:prefix, uid: "10.14455") }
  let!(:client) { create(:client, provider: provider) }
  let!(:datacite_doi) { create(:doi, client: client, type: "DataciteDoi", doi: (prefix.uid + "/" + Faker::Internet.password(min_length: 8)).downcase) }
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

  describe "GET /dois/DOI/media" do
    it "returns media" do
      get "/dois/#{datacite_doi.doi}/media", nil, headers

      expect(last_response.status).to eq(200)
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(6)
      result = json["data"].first
      expect(result.dig("attributes", "mediaType")).to eq("application/json")
    end
  end

  describe "GET /media query by doi not found" do
    it "returns media" do
      get "/dois/xxx/media", nil, headers

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
      get "/dois/xxx/media", nil, headers

      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /dois/DOI/media/:id" do
    context "when the record exists" do
      it "returns the media" do
        get "/dois/#{datacite_doi.doi}/media/#{media.uid}",
            nil, headers

        expect(json).not_to be_empty
        expect(json.dig("data", "id")).to eq(media.uid)
      end

      it "returns status code 200" do
        get "/dois/#{datacite_doi.doi}/media/#{media.uid}",
            nil, headers

        expect(last_response.status).to eq(200)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/dois/#{datacite_doi.doi}/media/xxxx",
            nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a not found message" do
        get "/dois/#{datacite_doi.doi}/media/xxxx",
            nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "POST /media" do
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
        post "/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(json.dig("data", "attributes", "mediaType")).to eq(media_type)
        expect(json.dig("data", "attributes", "url")).to eq(url)
      end

      it "returns status code 201" do
        post "/dois/#{datacite_doi.doi}/media",
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
        post "/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(last_response.status).to eq(201)
      end

      it "creates a media record" do
        post "/dois/#{datacite_doi.doi}/media",
             valid_attributes, headers

        expect(json.dig("data", "attributes", "url")).to eq(url)
      end
    end
  end

  describe "PATCH /dois/DOI/media/:id" do
    context "when the request is valid" do
      let(:media_type) { "application/xml" }

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
        patch "/dois/#{datacite_doi.doi}/media/#{media.uid}",
              valid_attributes, headers

        expect(json.dig("data", "attributes", "mediaType")).to eq(media_type)
        expect(json.dig("data", "attributes", "url")).to eq(url)
        expect(json.dig("data", "attributes", "version")).to be > 0
      end

      it "returns status code 200" do
        patch "/dois/#{datacite_doi.doi}/media/#{media.uid}",
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
        patch "/dois/#{datacite_doi.doi}/media/#{media.uid}",
              params, headers

        expect(last_response.status).to eq(422)
      end

      it "returns a validation failure message" do
        patch "/dois/#{datacite_doi.doi}/media/#{media.uid}",
              params, headers

        expect(json["errors"].first).to eq(
          "source" => "url", "title" => "Is invalid",
        )
      end
    end
  end

  describe "DELETE /dois/DOI/media/:id" do
    context "when the resources does exist" do
      it "returns status code 204" do
        delete "/dois/#{datacite_doi.doi}/media/#{media.uid}",
               nil, headers

        expect(last_response.status).to eq(204)
      end
    end

    context "when the resources doesnt exist" do
      it "returns status code 404" do
        delete "/dois/#{datacite_doi.doi}/media/xxx",
               nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/dois/#{datacite_doi.doi}/media/xxx",
               nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end
end
