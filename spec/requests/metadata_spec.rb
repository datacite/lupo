# frozen_string_literal: true

require "rails_helper"

describe MetadataController, type: :request do
  let(:provider) { create(:provider, symbol: "ADMIN") }
  let(:client) { create(:client, provider: provider) }
  let(:datacite_doi) { create(:doi, client: client, type: "DataciteDoi") }
  let(:xml) { file_fixture("datacite.xml").read }
  let!(:metadatas) { create_list(:metadata, 5, doi: datacite_doi, xml: xml) }
  let!(:metadata) { create(:metadata, doi: datacite_doi, xml: xml) }
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

  describe "GET /dois/DOI/metadata/:id" do
    context "when the record exists" do
      it "returns the Metadata" do
        get "/dois/#{datacite_doi.doi}/metadata/#{metadata.uid}",
            nil, headers

        expect(json).not_to be_empty
        expect(json.dig("data", "id")).to eq(metadata.uid)
      end

      it "returns status code 200" do
        get "/dois/#{datacite_doi.doi}/metadata/#{metadata.uid}",
            nil, headers

        expect(last_response.status).to eq(200)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/dois/#{datacite_doi.doi}/metadata/xxxx",
            nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a not found message" do
        get "/dois/#{datacite_doi.doi}/metadata/xxxx",
            nil, headers

        expect(json["errors"]).to eq(
          [
            {
              "status" => "404",
              "title" => "The resource you are looking for doesn't exist.",
            },
          ],
        )
      end
    end
  end

  describe "POST /metadata" do
    context "when the request is valid" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes" => { "xml" => Base64.strict_encode64(xml) },
          },
        }
      end

      it "creates a metadata record" do
        post "/dois/#{datacite_doi.doi}/metadata",
             valid_attributes, headers

        expect(Base64.decode64(json.dig("data", "attributes", "xml"))).to eq(
          xml,
        )
        expect(json.dig("data", "attributes", "namespace")).to eq(
          "http://datacite.org/schema/kernel-4",
        )
      end

      it "returns status code 201" do
        post "/dois/#{datacite_doi.doi}/metadata",
             valid_attributes, headers

        expect(last_response.status).to eq(201)
      end
    end

    context "when the xml is missing" do
      let(:not_valid_attributes) { { "data" => { "type" => "metadata" } } }

      it "returns status code 422" do
        post "/dois/#{datacite_doi.doi}/metadata",
             not_valid_attributes, headers

        expect(last_response.status).to eq(422)
      end

      it "returns a validation failure message" do
        debugger
        post "/dois/#{datacite_doi.doi}/metadata",
             not_valid_attributes, headers
        debugger

        expect(json["errors"]).to eq(
          [{ "source" => "xml", "title" => "Can't be blank" }],
        )
      end
    end

    context "when the XML is not valid draft status" do
      let(:xml) { file_fixture("datacite_missing_creator.xml").read }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes" => { "xml" => Base64.strict_encode64(xml) },
            "relationships" => {
              "doi" => {
                "data" => { "type" => "dois", "id" => datacite_doi.doi },
              },
            },
          },
        }
      end

      it "returns status code 201" do
        post "/dois/#{datacite_doi.doi}/metadata",
             valid_attributes, headers

        expect(last_response.status).to eq(201)
      end
    end
  end

  describe "DELETE /dois/DOI/metadata/:id" do
    context "when the resources does exist" do
      it "returns status code 204" do
        delete "/dois/#{datacite_doi.doi}/metadata/#{metadata.uid}",
               nil, headers

        expect(last_response.status).to eq(204)
      end
    end

    context "when the resources doesnt exist" do
      it "returns status code 404" do
        delete "/dois/#{datacite_doi.doi}/metadata/xxx",
               nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/dois/#{datacite_doi.doi}/metadata/xxx",
               nil, headers

        expect(json["errors"]).to eq(
          [
            {
              "status" => "404",
              "title" => "The resource you are looking for doesn't exist.",
            },
          ],
        )
      end
    end
  end
end
