require 'rails_helper'

RSpec.describe "Providers", type: :request  do
  # initialize test data
  let!(:providers)  { create_list(:provider, 10) }
  let!(:provider) { providers.first }
  let(:params) do
    { "data" => { "type" => "providers",
                  "attributes" => {
                    "uid" => "BL",
                    "name" => "British Library",
                    "contact_email" => "bob@example.com",
                    "country_code" => "GB" } } }
  end
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN'] } }

  # Test suite for GET /providers
  describe 'GET /providers' do
    # make HTTP get request before each example
    before { get '/providers', headers: headers }

    it 'returns providers' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /providers/:id
  describe 'GET /providers/:id' do
    before { get "/providers/#{provider.uid}" , headers: headers}

    context 'when the record exists' do
      it 'returns the provider' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(provider.uid.downcase)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/providers/xxx" , headers: headers}

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The page you are looking for doesn't exist.")
      end
    end
  end

  # Test suite for POST /providers
  describe 'POST /providers' do
    context 'when the request is valid' do
      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'region')).to eq("EMEA")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "uid" => "BL",
                        "name" => "British Library",
                        "country_code" => "GB" } } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"contact_email", "title"=>"Contact email can't be blank")
      end
    end

    context 'when the request is missing a data object' do
      let(:params) do
        { "type" => "providers",
          "attributes" => {
            "uid" => "BL",
            "name" => "British Library",
            "country_code" => "GB" } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"contact_email", "title"=>"Contact email can't be blank")
      end
    end
  end

  # # Test suite for PUT /providers/:id
  describe 'PUT /providers/:id' do
    context 'when the record exists' do
      before { put "/providers/#{provider.uid}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'region')).to eq("EMEA")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /providers/:id
  describe 'DELETE /providers/:id' do
    before { delete "/providers/#{provider.uid}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
