require 'rails_helper'

describe 'Periodicals', type: :request, elasticsearch: true do
  let(:ids) { clients.map { |c| c.uid }.join(",") }
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
  let!(:client) { create(:client, provider: provider, client_type: "periodical") }
  let(:params) do
    { "data" => { "type" => "periodicals",
                  "attributes" => {
                    "symbol" => provider.symbol + ".IMPERIAL",
                    "name" => "Imperial College",
                    "contactName" => "Madonna",
                    "contactEmail" => "bob@example.com",
                    "clientType" => "periodical",
                    "issn" => ["2328-1316"]
                  },
                  "relationships": {
              			"provider": {
              				"data":{
              					"type": "providers",
              					"id": provider.symbol.downcase
              				}
              			}
              		}} }
  end
  let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + bearer}}
  let(:query) { "jamon"}

  describe 'GET /periodicals', elasticsearch: true do
    let!(:clients)  { create_list(:client, 3, client_type: "periodical") }

    before do
      Client.import
      sleep 1
    end

    it 'returns periodicals' do
      get '/periodicals', nil, headers

      expect(last_response.status).to eq(200)
      expect(json['data'].size).to eq(4)
      expect(json.dig('meta', 'total')).to eq(4)
    end
  end

  # # Test suite for GET /clients
  # describe 'GET /clients query' do
  #   before { get "/clients?query=#{query}", headers: headers }
  #
  #   it 'returns clients' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(11)
  #   end
  #
  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  # describe 'GET /clients?ids=', elasticsearch: true do
  #   before do
  #     sleep 1
  #     get "/clients?ids=#{ids}", headers: headers
  #   end

  #   it 'returns clients' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(10)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  describe 'GET /periodicals/:id' do
    context 'when the record exists' do
      it 'returns the periodical' do
        get "/periodicals/#{client.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq(client.name)
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/periodicals/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /periodicals' do
    context 'when the request is valid' do    
      it 'creates a client' do
        post '/periodicals', params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig('data', 'attributes')
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["contactName"]).to eq("Madonna")

        relationships = json.dig('data', 'relationships')
        expect(relationships.dig("provider", "data", "id")).to eq(provider.symbol.downcase)
      end
    end

    context 'when the issn is in the wrong format' do
      let(:params) do
        { "data" => { "type" => "periodicals",
                      "attributes" => {
                        "symbol" => provider.symbol + ".IMPERIAL",
                        "name" => "Imperial College",
                        "contactName" => "Madonna",
                        "contactEmail" => "bob@example.com",
                        "clientType" => "periodical",
                        "issn" => ["2328-13XX"]
                      },
                      "relationships": {
                        "provider": {
                          "data":{
                            "type": "providers",
                            "id": provider.symbol.downcase
                          }
                        }
                      }} }
      end

      it 'returns an error' do
        post '/periodicals', params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"issn", "title"=>"Issn 2328-13xx is in the wrong format."}])
      end
    end

    context 'when the request is invalid' do
      let(:params) do
        { "data" => { "type" => "periodicals",
                      "attributes" => {
                        "symbol" => provider.symbol + ".IMPERIAL",
                        "name" => "Imperial College",
                        "contactName" => "Madonna"
                      },
                      "relationships": {
                  			"provider": {
                  				"data": {
                  					"type": "providers",
                  					"id": provider.symbol.downcase
                  				}
                  			}
                  		}} }
      end

      it 'returns status code 422' do
        post '/periodicals', params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"contact_email", "title"=>"Can't be blank"}, {"source"=>"contact_email", "title"=>"Is invalid"}])
      end
    end
  end

  describe 'PUT /periodicals/:id' do
    context 'when the record exists' do
      let(:params) do
        { "data" => { "type" => "periodicals",
                      "attributes" => {
                        "name" => "Imperial College 2",
                        "clientType" => "repository"}} }
      end

      it 'updates the record' do
        put "/periodicals/#{client.symbol.downcase}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College 2")
        expect(json.dig('data', 'attributes', 'name')).not_to eq(client.name)
        expect(json.dig('data', 'attributes', 'clientType')).to eq("repository")
      end
    end

    context 'using basic auth', vcr: true do
      let(:params) do
        { "data" => { "type" => "periodicals",
                      "attributes" => {
                        "name" => "Imperial College 2"}} }
      end
      let(:credentials) { provider.encode_auth_param(username: provider.symbol.downcase, password: "12345") }
      let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials } }

      it 'updates the record' do
        put "/periodicals/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College 2")
        expect(json.dig('data', 'attributes', 'name')).not_to eq(client.name)
      end
    end

    context 'when the request is invalid' do
      let(:params) do
        { "data" => { "type" => "periodicals",
                      "attributes" => {
                        "symbol" => client.symbol + "MegaCLient",
                        "email" => "bob@example.com",
                        "name" => "Imperial College"}} }
      end

      it 'returns status code 422' do
        put "/periodicals/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"symbol", "title"=>"Cannot be changed")
      end
    end
  end

  describe 'DELETE /periodicals/:id' do
    it 'returns status code 204' do
      delete "/periodicals/#{client.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end

    context 'when the resource doesnt exist' do
      it 'returns status code 404' do
        delete '/periodicals/xxx', nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe "doi transfer", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client) }
    let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET", name: "Target Client") }
    let(:params) do
      { "data" => { "type" => "periodicals",
                    "attributes" => {
                      "targetId" => target.symbol }} }
    end

    before do
      Doi.import
      sleep 1
    end

    it 'returns status code 200' do
      put "/periodicals/#{client.symbol}", params, headers
      sleep 1

      expect(last_response.status).to eq(200)
    end

    # it "transfered all DOIs" do
    #   expect(Doi.query(nil, client_id: client.symbol.downcase).results.total).to eq(0)
    #   expect(Doi.query(nil, client_id: target.symbol.downcase).results.total).to eq(3)
    # end
  end
end
