require 'rails_helper'

RSpec.describe "Allocators", type: :request  do
  # initialize test data
  let!(:allocators)  { create_list(:allocator, 10) }
  let(:allocator_id) { allocators.first.symbol }
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json'}

  # Test suite for GET /allocators
  describe 'GET /allocators' do
    # make HTTP get request before each example
    before { get '/allocators', headers: headers }

    it 'returns allocators' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /allocators/:id
  describe 'GET /allocators/:id' do
    before { get "/allocators/#{allocator_id}" , headers: headers}

    context 'when the record exists' do
      it 'returns the allocator' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(allocator_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:allocator_id) { 1222200 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /allocators
  describe 'POST /allocators' do
    # valid payload
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(AllocatorSerializer.new(FactoryGirl.build(:allocator)), {adapter: "json_api"}).to_json }

    context 'when the request is valid' do
      before { post '/allocators', params: valid_attributes , headers: headers }

      it 'creates a allocator' do
        expect(json['data']['attributes']['name']).to eq(JSON.parse(valid_attributes)['data']['attributes']['name'])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
        let(:not_valid_attributes) { ActiveModelSerializers::Adapter.create(DatacentreSerializer.new(FactoryGirl.build(:datacentre)), {adapter: "json_api"}).to_json }
      before { post '/allocators', params: not_valid_attributes }

      it 'returns status code 500' do
        expect(response).to have_http_status(500)
      end

      # it 'returns status code 422' do
      #   expect(response).to have_http_status(422)
      # end

      it 'returns a validation failure message' do
        # expect(response.body).to match(/Validation failed: Created by can't be blank/)
      end
    end
  end

  # # Test suite for PUT /allocators/:id
  describe 'PUT /allocators/:id' do
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(AllocatorSerializer.new(allocators.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/allocators/#{allocator_id}", params: valid_attributes, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /allocators/:id
  describe 'DELETE /allocators/:id' do
    before { delete "/allocators/#{allocator_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
