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

    it 'returns works', vcr: true do
      get '/works'

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(3)
      expect(json.dig('meta', 'total')).to eq(3)
    end
  end

  describe "citations", elasticsearch: true, vcr: true do
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by") }

    before do
      Doi.import
      Event.import
      sleep 1
    end

    it "has citations" do
      get "/works/#{doi.doi}"

      expect(last_response.status).to eq(200)
      expect(json.dig('data', 'attributes', 'url')).to eq(doi.url)
      expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      expect(json.dig('data', 'attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
      expect(json.dig('data', 'attributes', 'citation-count')).to eq(1)
      expect(json.dig('data', 'attributes', 'view-count')).to eq(0)
      expect(json.dig('data', 'attributes', 'views-over-time')).to eq([])
      expect(json.dig('data', 'attributes', 'download-count')).to eq(0)
      expect(json.dig('data', 'attributes', 'downloads-over-time')).to eq([])
    end

    it "has citations list" do
      get "/works"

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(2)
      expect(json.dig('meta', 'total')).to eq(2)
      work = json['data'].first
      expect(work.dig('attributes', 'doi')).to eq(doi.doi.downcase)
      expect(work.dig('attributes', 'title')).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig('attributes', 'citation-count')).to eq(1)
      expect(work.dig('attributes', 'view-count')).to eq(0)
      expect(work.dig('attributes', 'views-over-time')).to eq([])
      expect(work.dig('attributes', 'download-count')).to eq(0)
      expect(work.dig('attributes', 'downloads-over-time')).to eq([])
    end
  end

  describe 'GET /works/:id', elasticsearch: true do
    let!(:doi) { create(:doi, client: client, event: "publish") }

    before do
      Doi.import
      sleep 1
    end
  
    context 'when the record exists' do
      it 'returns the work' do
        get "/works/#{doi.doi}"

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

    context 'draft doi' do
      let!(:doi) { create(:doi, client: client) }

      it 'returns 404 status' do
        get "/works/#{doi.doi}", nil, headers

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

    context 'anonymous user draft doi' do
      let!(:doi) { create(:doi, client: client) }

      it 'returns 404 status' do
        get "/works/#{doi.doi}"

        expect(last_response.status).to eq(404)
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end
  end
end
