require 'rails_helper'

describe "Providers", type: :request  do
  # initialize test data
  let!(:providers)  { create_list(:provider, 10) }
  let!(:provider) { providers.first }
  let(:token) { User.generate_token }
  let(:params) do
    { "data" => { "type" => "providers",
                  "attributes" => {
                    "symbol" => "BL",
                    "name" => "British Library",
                    "contact-email" => "bob@example.com",
                    "country-code" => "GB" } } }
  end
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + token } }

  # Test suite for GET /providers
  describe 'GET /providers' do
    # make HTTP get request before each example
    before { get '/providers', headers: headers }

    it 'returns providers' do
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /providers/:id
  describe 'GET /providers/:id' do
    before { get "/providers/#{provider.symbol}" , headers: headers}
    context 'when the record exists' do
      it 'returns the provider' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(provider.symbol.downcase)
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
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /providers' do
    context 'request is valid' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "BL",
                        "name" => "British Library",
                        "region" => "EMEA",
                        "contact-email" => "doe@joe.joe",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contact-email')).to eq("doe@joe.joe")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'request for admin provider' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "ADMIN",
                        "name" => "Admin",
                        "region" => "EMEA",
                        "role_name" => "ROLE_ADMIN",
                        "contact-email" => "doe@joe.joe",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contact-email')).to eq("doe@joe.joe")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'request uses basic auth' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "BL",
                        "name" => "British Library",
                        "region" => "EMEA",
                        "contact-email" => "doe@joe.joe",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end
      let(:admin) { create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345") }
      let(:credentials) { admin.encode_auth_param(username: "ADMIN", password: "12345") }
      let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Basic ' + credentials } }

      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contact-email')).to eq("doe@joe.joe")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "BL",
                        "name" => "British Library",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
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
            "symbol" => "BL",
            "contact-name" => "timAus",
            "name" => "British Library",
            "country-code" => "GB" } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'returns status code 500' do
        expect(response).to have_http_status(500)
      end

      # it 'returns a validation failure message' do
      #   expect(response["exception"]).to eq("#<JSON::ParserError: You need to provide a payload following the JSONAPI spec>")
      # end
    end
  end

  describe 'PUT /providers/:id' do
    context 'when the record exists' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "name" => "British Library",
                        "region" => "Americas",
                        "contact-email" => "Pepe@mdm.cod",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end
      before { put "/providers/#{provider.symbol}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'contact-name')).to eq("timAus")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'using basic auth' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "name" => "British Library",
                        "region" => "Americas",
                        "contact-email" => "Pepe@mdm.cod",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end
      let(:admin) { create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345") }
      let(:credentials) { admin.encode_auth_param(username: "ADMIN", password: "12345") }
      let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Basic ' + credentials } }

      before { put "/providers/#{provider.symbol}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'contact-name')).to eq("timAus")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the resource doesn\'t exist' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "name" => "British Library",
                        "region" => "Americas",
                        "contact-email" => "Pepe@mdm.cod",
                        "contact-name" => "timAus",
                        "country-code" => "GB" } } }
      end

      before { put '/providers/xxx', params: params.to_json, headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  # Test suite for DELETE /providers/:id
  describe 'DELETE /providers/:id' do
    before { delete "/providers/#{provider.symbol}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
    context 'when the resources doesnt exist' do
      before { delete '/providers/xxx', params: params.to_json, headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end
end
