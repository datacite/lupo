require 'rails_helper'

describe "works", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + admin_bearer}}

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let!(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { 'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer }}

  describe 'GET /works', elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client, event: "publish") }
  
    before do
      Doi.import
      sleep 1
    end

    it 'returns dois', vcr: true do
      get '/works', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(3)
      expect(json.dig('meta', 'total')).to eq(3)
    end
  end

  describe 'GET /works/:id', elasticsearch: true do
    let!(:doi) { create(:doi, client: client, event: "publish") }

    before do
      Doi.import
      sleep 1
    end
  
    context 'when the record exists' do
      it 'returns the Doi' do
        get "/works/#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
        expect(json.dig('data', 'attributes', 'author').length).to eq(8)
        expect(json.dig('data', 'attributes', 'author').first).to eq("family"=>"Ollomo", "given"=>"Benjamin")
        expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
        expect(json.dig('data', 'attributes', 'description')).to eq("Data from: A new malaria agent in African hominids.")
        expect(json.dig('data', 'attributes', 'container-title')).to eq("Dryad Digital Repository")
        expect(json.dig('data', 'attributes', 'published')).to eq("2011")
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/works/10.5256/xxxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end

    context 'anonymous user' do
      it 'returns the Doi' do
        get "/works/#{doi.doi}"

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end
    end
  end
end
