require 'rails_helper'

RSpec.describe "Members", type: :request  do
  # initialize test data
  let!(:members)  { create_list(:member, 10) }
  let(:member_id) { members.first.symbol.downcase }

  auth = 'Bearer ' + ENV['JWT_TOKEN']
  headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => auth}

  # Test suite for GET /members
  describe 'GET /members' do
    # make HTTP get request before each example
    before { get '/members', headers: headers }

    it 'returns members' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /members/:id
  describe 'GET /members/:id' do
    before { get "/members/#{member_id}" , headers: headers}

    context 'when the record exists' do
      it 'returns the member' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(member_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:member_id) { 1222200 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /members
  describe 'POST /members' do
    # valid payload
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(MemberSerializer.new(FactoryGirl.build(:member)), {adapter: "json_api"}).to_json }

    context 'when the request is valid' do
      before { post '/members', params: valid_attributes , headers: headers }

      it 'creates a member' do
        expect(json['data']['attributes']['name']).to eq(JSON.parse(valid_attributes)['data']['attributes']['name'])
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
        let(:not_valid_attributes) { ActiveModelSerializers::Adapter.create(DatacentreSerializer.new(FactoryGirl.build(:datacentre)), {adapter: "json_api"}).to_json }
      before { post '/members', params: not_valid_attributes }

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

  # # Test suite for PUT /members/:id
  describe 'PUT /members/:id' do
    let(:valid_attributes) { ActiveModelSerializers::Adapter.create(MemberSerializer.new(members.first), {adapter: "json_api"}).to_json }

    context 'when the record exists' do
      before { put "/members/#{member_id}", params: valid_attributes, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /members/:id
  describe 'DELETE /members/:id' do
    before { delete "/members/#{member_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
