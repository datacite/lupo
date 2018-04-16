require 'rails_helper'

describe "Client Prefixes", type: :request do
  let!(:client_prefixes)  { create_list(:client_prefix, 5) }
  let(:client_prefix) { create(:client_prefix) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

  describe 'GET /client-prefixes' do
    before { get '/client-prefixes', headers: headers }

    it 'returns client-prefixes' do
      expect(json['data'].size).to eq(5)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /client-prefixes/:uid' do
    before { get "/client-prefixes/#{client_prefix.uid}", headers: headers }

    context 'when the record exists' do
      it 'returns the client-prefix' do
        expect(json.dig("data", "id")).to eq(client_prefix.uid)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/client-prefixes/xxx" , headers: headers}

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /client-prefixes' do
    context 'when the request is valid' do
      let(:provider) { create(:provider) }
      let(:client) { create(:client, provider: provider) }
      let(:prefix) { create(:prefix) }
      let(:provider_prefix) { create(:provider_prefix, provider: provider, prefix: prefix) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "provider-prefixes",
            "relationships": {
              "client": {
                "data":{
                  "type": "clients",
                  "id": client.symbol.downcase
                }
              },
              "provider-prefix": {
                "data":{
                  "type": "provider-prefixes",
                  "id": provider_prefix.prefix
                }
              },
              "prefix": {
                "data":{
                  "type": "prefixes",
                  "id": prefix.prefix
                }
              }
            }
          }
        }
      end

      before { post '/client-prefixes', params: valid_attributes.to_json, headers: headers }

      it 'creates a client-prefix' do
        expect(json.dig('data', 'id')).not_to be_nil
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let!(:client)  { create(:client) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "client-prefixes"
          }
        }
      end

      before { post '/client-prefixes', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("source"=>"client", "title"=>"Must exist")
      end
    end
  end

  describe 'POST /client-prefixes/set-created' do
    before { post '/client-prefixes/set-created', headers: headers }

    it 'returns success' do
      expect(json['message']).to eq("Client prefix created timestamp added.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /client-prefixes/set-provider' do
    before { post '/client-prefixes/set-provider', headers: headers }

    it 'returns success' do
      expect(json['message']).to eq("Client prefix associated provider prefix added.")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
