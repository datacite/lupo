require 'rails_helper'

describe RepositoryPrefixesController, type: :request, elasticsearch: true do
  let(:prefix) { create(:prefix) }
  let(:provider) { create(:provider) }
  let(:client) { create(:client, provider: provider) }
  let(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
  let!(:client_prefixes) { create_list(:client_prefix, 5) }
  let(:client_prefix) { create(:client_prefix, client: client, prefix: prefix, provider_prefix: provider_prefix) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}

  describe 'GET /repository-prefixes' do
    before do
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    it 'returns repository-prefixes' do
      get '/repository-prefixes', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(5)
    end

    it 'returns repository-prefixes by repository-id' do
      get "/repository-prefixes?repository-id=#{client_prefixes.first.client_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(1)
    end

    it 'returns repository-prefixes by prefix-id' do
      get "/repository-prefixes?prefix-id=#{client_prefixes.first.prefix_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(1)
    end

    it 'returns repository-prefixes by partial prefix' do
      get "/repository-prefixes?query=10.508", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(5)
    end

    it 'returns repository-prefixes by repository-id and prefix-id' do
      get "/repository-prefixes?repository-id=#{client_prefixes.first.client_id}&#{client_prefixes.first.prefix_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(1)
    end

    it 'returns prefixes by client-id' do
      get "/prefixes?client-id=#{client_prefixes.first.client_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(1)
    end
  end

  describe 'GET /repository-prefixes/:uid' do
    before do
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    context 'when the record exists' do
      it 'returns the repository-prefix' do
        get "/repository-prefixes/#{client_prefix.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "id")).to eq(client_prefix.uid)
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/repository-prefixes/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'PATCH /repository-prefixes/:uid' do
    it 'returns method not supported error' do
      patch "/repository-prefixes/#{client_prefix.uid}", nil, headers

      expect(last_response.status).to eq(405)
      expect(json.dig("errors")).to eq([{"status"=>"405", "title"=>"Method not allowed"}])
    end
  end

  describe 'DELETE /repository-prefixes/:uid' do
    let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix, provider_prefix: provider_prefix) }

    before do
      ProviderPrefix.import
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    it 'deletes a repository-prefix' do
      delete "/repository-prefixes/#{client_prefix.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end
  end

  describe 'POST /repository-prefixes' do
    context 'when the request is valid' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "client-prefixes",
            "relationships": {
              "repository": {
                "data": {
                  "type": "repository",
                  "id": client.symbol.downcase,
                }
              },
              "provider-prefix": {
                "data": {
                  "type": "provider-prefix",
                  "id": provider_prefix.uid,
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

      it 'creates a repository-prefix' do
        post '/repository-prefixes', valid_attributes, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'id')).not_to be_nil
      end
    end

    context 'when the request is invalid' do
      let!(:client) { create(:client) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "repository-prefixes"
          }
        }
      end

      it 'returns status code 422' do
        post '/repository-prefixes', not_valid_attributes, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"client", "title"=>"Must exist")
      end
    end
  end
end
