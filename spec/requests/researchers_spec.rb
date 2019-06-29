require 'rails_helper'

describe "Researchers", type: :request, elasticsearch: true  do
  let!(:researcher) { create(:researcher) }
  let(:token) { User.generate_token }
  let(:params) do
    { "data" => { "type" => "researchers",
                  "attributes" => {
                    "name" => "Martin Fenner" } } }
  end
  let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + token } }

  describe 'GET /researchers' do
    let!(:researchers)  { create_list(:researcher, 3) }

    before do
      Researcher.import
      sleep 1
    end

    it "returns researchers" do
      get "/researchers", nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(4)
      expect(json.dig('meta', 'total')).to eq(4)
    end
  end

  describe 'GET /researchers/:id' do
    context 'when the record exists' do
      it 'returns the researcher' do
        get "/researchers/#{researcher.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json['data']['id']).to eq(researcher.uid)
        expect(json['data']['attributes']['name']).to eq(researcher.name)
      end
    end
  end

  describe 'POST /researchers' do
    context 'request is valid' do
      let(:params) do
        { "data" => { "type" => "researchers",
                      "attributes" => {
                        "uid" => "0000-0003-2584-9687",
                        "name" => "James Gill",
                        "givenNames" => "James",
                        "familyName" => "Gill" } } }
      end

      it 'creates a researcher' do
        post '/researchers', params, headers

        expect(json.dig('data', 'attributes', 'name')).to eq("James Gill")
      end

      it 'returns status code 201' do
        post '/researchers', params, headers

        expect(last_response.status).to eq(201)
      end
    end

    context 'request uses basic auth' do
      let(:params) do
        { "data" => { "type" => "researchers",
                      "attributes" => {
                        "uid" => "0000-0003-2584-9687",
                        "name" => "James Gill" } } }
      end
      let(:admin) { create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345") }
      let(:credentials) { admin.encode_auth_param(username: "ADMIN", password: "12345") }
      let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials } }

      it 'creates a researcher' do
        post '/researchers', params, headers

        expect(last_response.status).to eq(201)
        expect(json.dig('data', 'attributes', 'name')).to eq("James Gill")
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "researchers",
                      "attributes" => { } } }
      end

      it 'returns a validation failure message' do
        post '/researchers', params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"uid", "title"=>"Can't be blank")
      end
    end

    context 'when the request is missing a data object' do
      let(:params) do
        { "type" => "researchers",
          "attributes" => {
            "uid" => "0000-0003-2584-9687",
            "name" => "James Gill"  } }
      end

      it 'returns status code 400' do
        post '/researchers', params, headers

        expect(last_response.status).to eq(400)
      end

      # it 'returns a validation failure message' do
      #   expect(response["exception"]).to eq("#<JSON::ParserError: You need to provide a payload following the JSONAPI spec>")
      # end
    end
  end

  describe 'PUT /researchers/:id' do
    context 'when the record exists' do
      let(:params) do
        { "data" => { "type" => "researchers",
                      "attributes" => {
                        "name" => "James Watt" } } }
      end

      it 'updates the record' do
        put "/researchers/#{researcher.uid}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("James Watt")
      end
    end
  end

  # # Test suite for DELETE /researchers/:id
  # describe 'DELETE /researchers/:id' do
  #   before { delete "/researchers/#{researcher.symbol}", headers: headers }

  #   it 'returns status code 204' do
  #     expect(response).to have_http_status(204)
  #   end
  #   context 'when the resources doesnt exist' do
  #     before { delete '/researchers/xxx', params: params.to_json, headers: headers }

  #     it 'returns status code 404' do
  #       expect(response).to have_http_status(404)
  #     end

  #     it 'returns a validation failure message' do
  #       expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
  #     end
  #   end
  # end

  # describe 'POST /researchers/set-test-prefix' do
  #   before { post '/researchers/set-test-prefix', headers: headers }

  #   it 'returns success' do
  #     expect(json['message']).to eq("Test prefix added.")
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end
end
