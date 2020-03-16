require 'rails_helper'

describe "Provider Prefixes", type: :request, elasticsearch: true do
  let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let(:provider) { create(:provider, consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION", password_input: "12345") }
  let(:prefix) { create(:prefix) }
  let!(:provider_prefixes) { create_list(:provider_prefix, 3, provider: provider) }
  let!(:provider_prefixes2) { create_list(:provider_prefix, 2) }
  let(:provider_prefix) { create(:provider_prefix) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}

  before do
    ProviderPrefix.import
    Prefix.import
    Provider.import
    sleep 2
  end

  describe "GET /provider-prefixes by consortium" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?consortium-id=#{consortium.symbol.downcase}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
    end
  end

  describe "GET /provider-prefixes by provider" do
    it "returns provider-prefixes" do
      get "/provider-prefixes?provider-id=#{provider.symbol.downcase}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
    end
  end

  describe 'GET /provider-prefixes' do
    it 'returns provider-prefixes' do
      get '/provider-prefixes', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(5)
    end
  end

  describe 'GET /provider-prefixes/:uid' do
    context 'when the record exists' do
      it 'returns the provider-prefix' do
        get "/provider-prefixes/#{provider_prefix.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(provider_prefix.uid)
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/provider-prefixes/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'PATCH /provider-prefixes/:uid' do
    it 'returns method not supported error' do
      patch "/provider-prefixes/#{provider_prefix.uid}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json.dig("errors")).to eq([{"status"=>"405", "title"=>"Method not allowed"}])
    end
  end

  describe 'POST /provider-prefixes' do
    context 'when the request is valid' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "provider-prefixes",
            "relationships": {
              "provider": {
                "data": {
                  "type": "provider",
                  "id": provider.symbol.downcase,
                }
              },
              "prefix": {
                "data": {
                  "type": "prefix",
                  "id": prefix.uid,
                }
              }
            }
          }
        }
      end

      it 'creates a provider-prefix' do
        post '/provider-prefixes', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'id')).not_to be_nil
      end
    end

    context 'when the request is invalid' do
      let!(:provider) { create(:provider) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "provider-prefixes"
          }
        }
      end

      it 'returns status code 422' do
        post '/provider-prefixes', not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"provider", "title"=>"Must exist")
      end
    end
  end
end
