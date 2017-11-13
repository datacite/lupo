require 'rails_helper'

RSpec.describe "Client Prefixes", type: :request   do
  let!(:client_prefixes)  { create_list(:client_prefix, 5) }
  let(:client_prefix) { client_prefixes.first }
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
end
