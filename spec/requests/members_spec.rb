require 'rails_helper'

RSpec.describe "Members", type: :request  do
  # initialize test data
  let!(:members)  { create_list(:member, 10) }
  let!(:member) { members.first }
  let(:params) do
    { "data" => { "type" => "members",
                  "attributes" => {
                    "uid" => "BL",
                    "name" => "British Library",
                    "contact_email" => "bob@example.com",
                    "country_code" => "GB" } } }
  end
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN'] } }

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
    before { get "/members/#{member.uid}" , headers: headers}

    context 'when the record exists' do
      it 'returns the member' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(member.uid.downcase)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/members/xxx" , headers: headers}

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The page you are looking for doesn't exist.")
      end
    end
  end

  # Test suite for POST /members
  describe 'POST /members' do
    context 'when the request is valid' do
      before { post '/members', params: params.to_json, headers: headers }

      it 'creates a member' do
        expect(json.dig('data', 'attributes', 'region')).to eq("EMEA")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "members",
                      "attributes" => {
                        "uid" => "BL",
                        "name" => "British Library",
                        "country_code" => "GB" } } }
      end

      before { post '/members', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"contact_email", "title"=>"Contact email can't be blank")
      end
    end

    context 'when the request is missing a data object' do
      let(:params) do
        { "type" => "members",
          "attributes" => {
            "uid" => "BL",
            "name" => "British Library",
            "country_code" => "GB" } }
      end

      before { post '/members', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"contact_email", "title"=>"Contact email can't be blank")
      end
    end
  end

  # # Test suite for PUT /members/:id
  describe 'PUT /members/:id' do
    context 'when the record exists' do
      before { put "/members/#{member.uid}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'region')).to eq("EMEA")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /members/:id
  describe 'DELETE /members/:id' do
    before { delete "/members/#{member.uid}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
