require 'rails_helper'

RSpec.describe "Prefixes", type: :request   do
  # initialize test data
  let!(:prefixes)  { create_list(:prefix, 10) }
  let(:prefix_id) { prefixes.first.prefix }
  auth = 'Bearer ' + ENV['JWT_TOKEN']
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => auth}

  # Test suite for GET /prefixes
  describe 'GET /prefixes' do
    # make HTTP get request before each example
    before { get '/prefixes', headers: headers }

    it 'returns prefixes' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /prefixes/:id
  describe 'GET /prefixes/:id' do
    before { get "/prefixes/#{prefix_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the prefix' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(prefix_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:prefix_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /prefixes
  describe 'POST /prefixes' do
    # valid payload
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(PrefixSerializer.new(FactoryGirl.build(:prefix)), {adapter: "json_api"}).to_json }

    context 'when the request is valid' do
      before { post '/prefixes', params: valid_attributes, headers: headers }

      it 'creates a prefix' do
        expect(json['data']['attributes']['prefix']).to eq(JSON.parse(valid_attributes)['data']['attributes']['prefix'])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let(:not_valid_attributes) { ActiveModelSerializers::Adapter.create(DatacenterSerializer.new(FactoryGirl.build(:datacenter)), {adapter: "json_api"}).to_json }

      before { post '/prefixes', params: not_valid_attributes }

      it 'returns status code 500' do
        expect(response).to have_http_status(500)
      end
      # it 'returns status code 422' do
      #   expect(response).to have_http_status(422)
      # end

      # it 'returns a validation failure message' do
      #   expect(response.body).to match(/Validation failed: Created by can't be blank/)
      # end
    end
  end

  # # Test suite for PUT /prefixes/:id
  describe 'PUT /prefixes/:id' do
    let(:valid_attributes) {  ActiveModelSerializers::Adapter.create(PrefixSerializer.new(prefixes.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/prefixes/#{prefix_id}", params: valid_attributes , headers: headers}

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /prefixes/:id
  describe 'DELETE /prefixes/:id' do
    before { delete "/prefixes/#{prefix_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
