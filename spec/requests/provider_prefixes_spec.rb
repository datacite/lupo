# frozen_string_literal: true

require "rails_helper"

describe ProviderPrefixesController, type: :request, elasticsearch: true do
  let!(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let!(:provider) do
    create(
      :provider,
      consortium: consortium,
      role_name: "ROLE_CONSORTIUM_ORGANIZATION",
      password_input: "12345",
    )
  end
  let!(:prefix) { create(:prefix) }
  let!(:provider_prefixes) do
    [
      create(:provider_prefix, provider: provider, prefix: @prefix_pool[0]),
      create(:provider_prefix, provider: provider, prefix: @prefix_pool[1]),
      create(:provider_prefix, provider: provider, prefix: @prefix_pool[2])
    ]
  end
  let!(:provider_prefixes2) do
    [
      create(:provider_prefix, prefix: @prefix_pool[3]),
      create(:provider_prefix, prefix: @prefix_pool[4])
    ]
  end
  let!(:provider_prefix) { create(:provider_prefix, prefix: @prefix_pool[5]) }
  let!(:bearer) { User.generate_token(role_id: "staff_admin") }
  let!(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end

  before(:each) do
    ProviderPrefix.import
    Prefix.import
    Provider.import
    sleep 2
  end

  describe "GET /provider-prefixes by consortium" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?consortium-id=#{consortium.uid}",
          nil, headers

      current_year = Date.today.year.to_s
      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "years")).to eq(
        [{ "count" => 3, "id" => current_year, "title" => current_year }],
      )
      expect(json.dig("meta", "states")).to eq(
        [
          {
            "count" => 3,
            "id" => "without-repository",
            "title" => "Without Repository",
          },
        ],
      )
      expect(json.dig("meta", "providers")).to eq(
        [
          {
            "count" => 3,
            "id" => provider.uid,
            "title" => "My provider",
          },
        ],
      )
    end
  end

  describe "GET /provider-prefixes by provider" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?provider-id=#{provider.symbol.downcase}",
          nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
    end
  end

  describe "GET /provider-prefixes by prefix" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?prefix-id=#{provider_prefixes.first.prefix_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
    end
  end

  describe "GET /provider-prefixes by provider and prefix" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?provider-id=#{
            provider.uid
          }&prefix-id=#{provider_prefixes.first.prefix_id}",
          nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
    end
  end

  describe "GET /provider-prefixes by partial prefix" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?query=10.508", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(6)
    end
  end

  describe "GET /provider-prefixes" do
    it "returns provider-prefixes" do
      get "/provider-prefixes", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(6)
    end

    it "returns correct paging links" do
      get "/provider-prefixes", nil, headers
      self_link_absolute = Addressable::URI.parse(json.dig("links", "self"))
      expect(self_link_absolute.path).to eq("/provider-prefixes")
      expect(json.dig("links", "next")).to be_nil
    end
  end

  describe "GET /provider-prefixes/:uid" do
    context "when the record exists" do
      it "returns the provider-prefix" do
        get "/provider-prefixes/#{provider_prefix.uid}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(provider_prefix.uid)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/provider-prefixes/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "PATCH /provider-prefixes/:uid" do
    it "returns method not supported error" do
      patch "/provider-prefixes/#{provider_prefix.uid}",
            nil, headers

      expect(last_response.status).to eq(405)
      expect(json.dig("errors")).to eq(
        [{ "status" => "405", "title" => "Method not allowed" }],
      )
    end
  end

  describe "POST /provider-prefixes" do
    context "when the request is valid" do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "provider-prefixes",
            "relationships": {
              "provider": {
                "data": { "type": "provider", "id": provider.uid },
              },
              "prefix": { "data": { "type": "prefix", "id": prefix.uid } },
            },
          },
        }
      end

      before do
        Prefix.import
        Provider.import
        sleep 2
      end

      it "creates a provider-prefix" do
        post "/provider-prefixes", valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig("data", "id")).not_to be_nil

        sleep 2

        get "/prefixes?state=unassigned", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("meta", "total")).to eq(@prefix_pool.length - 6)


        delete "/provider-prefixes/#{provider_prefix.uid}", nil, headers

        expect(last_response.status).to eq(204)

        Prefix.import
        ProviderPrefix.import
        sleep 2

        get "/prefixes?state=unassigned", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("meta", "total")).to eq(@prefix_pool.length - 5)
      end
    end

    context "when the request is invalid" do
      let!(:provider) { create(:provider) }
      let(:not_valid_attributes) do
        { "data" => { "type" => "provider-prefixes" } }
      end

      it "returns status code 422" do
        post "/provider-prefixes",
             not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "provider", "title" => "Must exist",
        )
      end
    end
  end

  describe "DELETE /provider-prefixes/:uid" do
    let!(:provider_prefix) { create(:provider_prefix) }

    before do
      ProviderPrefix.import
      sleep 2
    end

    it "deletes the prefix" do
      delete "/provider-prefixes/#{provider_prefix.uid}",
             nil, headers
      expect(last_response.status).to eq(204)
    end
  end
end
