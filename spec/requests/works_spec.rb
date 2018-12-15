require 'rails_helper'

describe "works", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + admin_bearer}}

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let!(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let!(:dois) { create_list(:doi, 3, client: client, event: "publish") }
  let(:doi) { create(:doi, client: client, event: "publish") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { 'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

  describe 'GET /works', elasticsearch: true do
    before do
      sleep 1
      get '/works', headers: headers
    end

    # it 'returns dois' do
    #   expect(json['data'].size).to eq(0)
    # end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /works/:id' do
    context 'when the record exists' do
      before { get "/works/#{doi.doi}", headers: headers }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'author').length).to eq(8)
        expect(json.dig('data', 'attributes', 'author').first).to eq("family"=>"Ollomo", "given"=>"Benjamin")
        expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
        expect(json.dig('data', 'attributes', 'container-title')).to eq("Dryad Digital Repository")
        expect(json.dig('data', 'attributes', 'published')).to eq("2011")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/works/10.5256/xxxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context 'anonymous user' do
      before { get "/works/#{doi.doi}" }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end
end