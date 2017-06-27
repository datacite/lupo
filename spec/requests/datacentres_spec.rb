require 'rails_helper'

RSpec.describe 'Datacentres',  type: :request  do
  # initialize test data
  let!(:datacentres)  { create_list(:datacentre, 10) }
  let(:datacentre_id) { datacentres.first.symbol }
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json'}

  # Test suite for GET /datacentres
  describe 'GET /datacentres' do
    # make HTTP get request before each example
    before { get '/datacentres', headers: headers }

    it 'returns datacentres' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /datacentres/:id
  describe 'GET /datacentres/:id' do
    before { get "/datacentres/#{datacentre_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the datacentre' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(datacentre_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:datacentre_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /datacentres
  describe 'POST /datacentres' do
    # valid payload
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(DatacentreSerializer.new(FactoryGirl.build(:datacentre)), {adapter: "json_api"}).to_json }

    context 'when the request is valid' do
      before { post '/datacentres', params: valid_attributes, headers: headers }

      it 'creates a datacentre' do
        expect(json['data']['attributes']['name']).to eq(JSON.parse(valid_attributes)['data']['attributes']['name'])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let(:not_valid_attributes) { ActiveModelSerializers::Adapter.create(AllocatorSerializer.new(FactoryGirl.build(:allocator)), {adapter: "json_api"}).to_json }
      before { post '/datacentres', params: not_valid_attributes }

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

  # # Test suite for PUT /datacentres/:id
  describe 'PUT /datacentres/:id' do
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(DatacentreSerializer.new(datacentres.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/datacentres/#{datacentre_id}", params: valid_attributes, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /datacentres/:id
  describe 'DELETE /datacentres/:id' do
    before { delete "/datacentres/#{datacentre_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
