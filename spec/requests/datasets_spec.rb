require 'rails_helper'

RSpec.describe "Datasets", type: :request  do
  # initialize test data
  let!(:datasets)  { create_list(:dataset, 10) }
  let(:dataset_id) { datasets.first.doi }
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json'}

  # Test suite for GET /datasets
  describe 'GET /datasets' do
    # make HTTP get request before each example
    before { get '/datasets', headers: headers }

    it 'returns Datasets' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /datasets/:id
  describe 'GET /datasets/:id' do
    before { get "/datasets/#{dataset_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the Dataset' do
        expect(json).not_to be_empty
        expect(json['data']['attributes']['doi']).to eq(dataset_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:dataset_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /datasets
  describe 'POST /datasets' do
    # valid payload
    # let(:valid_attributes) { { doi: '10.5072/MRYN-36VS', datacentre: 121212} }
    #
    # context 'when the request is valid' do
    #   before { post '/datasets', params: valid_attributes, headers: headers }
    #
    #   it 'creates a Dataset' do
    #     puts json
    #     expect(json['doi']).to eq('10.5072/MRYN-36VS')
    #   end
    #
    #   it 'returns status code 201' do
    #     expect(response).to have_http_status(201)
    #   end
    # end
    #
    # context 'when the request is invalid' do
    #   before { post '/datasets', params: { datacentre: 222 }, headers: headers }
    #
    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   # it 'returns a validation failure message' do
    #   #   expect(response.body).to match(/Validation failed: Created by can't be blank/)
    #   # end
    # end
  end

  # # Test suite for PUT /datasets/:id
  describe 'PUT /datasets/:id' do
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(DatasetSerializer.new(datasets.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/datasets/#{dataset_id}", params: valid_attributes, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /datasets/:id
  describe 'DELETE /datasets/:id' do
    before { delete "/datasets/#{dataset_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
