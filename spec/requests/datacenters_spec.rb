require 'rails_helper'

RSpec.describe 'Datacenters',  type: :request  do
  # initialize test data
  let!(:datacenters)  { create_list(:datacenter, 10) }
  let(:datacenter_id) { datacenters.first.symbol.downcase }
  auth = 'Bearer ' + ENV['JWT_TOKEN']
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => auth}

  # Test suite for GET /datacenters
  describe 'GET /datacenters' do
    # make HTTP get request before each example
    before { get '/datacenters', headers: headers }

    it 'returns datacenters' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /datacenters/:id
  describe 'GET /datacenters/:id' do
    before { get "/datacenters/#{datacenter_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the datacenter' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(datacenter_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:datacenter_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /datacenters
  describe 'POST /datacenters' do
    # valid payload
    let!(:member)  { create(:member) }
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(DatacenterSerializer.new(FactoryGirl.build(:datacenter, member: member)), {adapter: "json_api"}).to_json }
    # let(:valid_attributes) { ActiveModelSerializers::SerializableResource.new(FactoryGirl.build(:datacenter, member: member)).to_json }

    context 'when the request is valid' do
      before { post '/datacenters', params: valid_attributes, headers: headers }
      it 'creates a datacenter' do
        expect(json['data']['attributes']['name']).to eq(JSON.parse(valid_attributes)['data']['attributes']['name'])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let(:not_valid_attributes) { ActiveModelSerializers::Adapter.create(MemberSerializer.new(FactoryGirl.build(:member)), {adapter: "json_api"}).to_json }
      before { post '/datacenters', params: not_valid_attributes }

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

  # # Test suite for PUT /datacenters/:id
  describe 'PUT /datacenters/:id' do
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(DatacenterSerializer.new(datacenters.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/datacenters/#{datacenter_id}", params: valid_attributes, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /datacenters/:id
  describe 'DELETE /datacenters/:id' do
    before { delete "/datacenters/#{datacenter_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
