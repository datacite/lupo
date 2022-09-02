# frozen_string_literal: true

require "rails_helper"

describe PrefixesController, type: :request, elasticsearch: true do
  let!(:prefixes) { create_list(:prefix, 10) }
  let(:bearer) { User.generate_token }
  let(:prefix_id) { prefixes.first.uid }
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end

  describe "GET /prefixes" do
    before do
      Prefix.import
      sleep 2
    end

    it "returns prefixes", :skip_prefix_pool do
      get "/prefixes", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
    end

    it "returns prefixes by id" do
      get "/prefixes?id=#{prefixes.first.uid}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
    end

    it "returns prefixes by query", :skip_prefix_pool do
      get "/prefixes?query=10.508", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
    end
  end

  describe "GET /prefixes/:id" do
    before do
      Prefix.import
      sleep 2
    end

    context "when the record exists" do
      it "returns status code 200" do
        get "/prefixes/#{prefix_id}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(prefix_id)
      end
    end

    context "when the prefix does not exist" do
      it "returns status code 404" do
        get "/prefixes/10.1234", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/prefixes/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "PATCH /prefixes/:prefix_id" do
    it "returns method not supported error" do
      patch "/prefixes/#{prefix_id}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json.dig("errors")).to eq(
        [{ "status" => "405", "title" => "Method not allowed" }],
      )
    end
  end

  describe "POST /prefixes" do
    before do
      Prefix.import
      sleep 2
    end

    context "when the request is valid" do
      let!(:provider) { create(:provider) }
      let(:valid_attributes) do
        { "data" => { "type" => "prefixes", "id" => "10.17177" } }
      end

      it "returns status code 201" do
        post "/prefixes", valid_attributes, headers

        expect(last_response.status).to eq(201)
      end
    end

    context "when the request is invalid" do
      let!(:provider) { create(:provider) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "prefixes", "attributes" => { "uid" => "dsds10.33342" }
          },
        }
      end

      it "returns status code 422" do
        post "/prefixes", not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "uid", "title" => "Can't be blank",
        )
      end
    end
  end

  describe "DELETE /prefixes/:id" do
    it "returns status code 204" do
      delete "/prefixes/#{prefix_id}", nil, headers

      expect(last_response.status).to eq(204)
    end
  end
end
