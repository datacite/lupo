require 'rails_helper'

RSpec.describe 'Datacenters', type: :request  do
  let!(:datacenters)  { create_list(:datacenter, 10) }
  let(:member) { create(:member) }
  let(:datacenter) { create(:datacenter) }
  let(:params) do
    { "data" => { "type" => "data-centers",
                  "attributes" => {
                    "uid" => "BL.IMPERIAL",
                    "name" => "Imperial College",
                    "member_id" => member.id,
                    "contact_email" => "bob@example.com" } } }
  end
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN']}}

  # Test suite for GET /data-centers
  describe 'GET /data-centers' do
    before { get '/data-centers', headers: headers }

    it 'returns datacenters' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(25)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /data-centers/:id
  describe 'GET /data-centers/:id' do
    before { get "/data-centers/#{datacenter.uid}", headers: headers }

    context 'when the record exists' do
      it 'returns the datacenter' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'attributes', 'name')).to eq(datacenter.name)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/data-centers/xxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/RecordNotFound/)
      end
    end
  end

  # Test suite for POST /data-centers
  describe 'POST /data-centers' do
    context 'when the request is valid' do
      before { post '/data-centers', params: params.to_json, headers: headers }
      it 'creates a datacenter' do
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let(:params) do
        { "data" => { "type" => "data-centers",
                      "attributes" => {
                        "name" => "Imperial College",
                        "contact_email" => "bob@example.com" } } }
      end

      before { post '/data-centers', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"uid", "title"=>"Uid can't be blank")
      end
    end
  end

  # # Test suite for PUT /data-centers/:id
  describe 'PUT /data-centers/:id' do
    context 'when the record exists' do
      before { put "/data-centers/#{datacenter.uid}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /data-centers/:id
  describe 'DELETE /data-centers/:id' do
    before { delete "/data-centers/#{datacenter.uid}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
