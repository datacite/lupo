require 'rails_helper'

describe 'Repositories', type: :request, elasticsearch: true do
  let(:ids) { clients.map { |c| c.uid }.join(",") }
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
  let!(:client) { create(:client, provider: provider, client_type: "repository") }
  let(:params) do
    { "data" => { "type" => "clients",
                  "attributes" => {
                    "symbol" => provider.symbol + ".IMPERIAL",
                    "name" => "Imperial College",
                    "systemEmail" => "bob@example.com",
                    "salesforceId" => "abc012345678901234",
                    "clientType" => "repository",
                    "certificate" => ["CoreTrustSeal"]
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

  describe 'GET /repositories', elasticsearch: true do
    let!(:clients)  { create_list(:client, 3) }

    before do
      Client.import
      sleep 1
    end

    it 'returns repositories' do
      get '/repositories', nil, headers

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

  describe 'GET /repositories/:id' do
    context 'when the record exists' do
      it 'returns the repository' do
        get "/repositories/#{client.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq(client.name)
        expect(json.dig('data', 'attributes', 'globusUuid')).to eq("bc7d0274-3472-4a79-b631-e4c7baccc667")
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/repositories/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /repositories' do
    context 'when the request is valid' do    
      it 'creates a repository' do
        post '/repositories', params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig('data', 'attributes')
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["systemEmail"]).to eq("bob@example.com")
        expect(attributes["certificate"]).to eq(["CoreTrustSeal"])
        expect(attributes["salesforceId"]).to eq("abc012345678901234")

        relationships = json.dig('data', 'relationships')
        expect(relationships.dig("provider", "data", "id")).to eq(provider.symbol.downcase)
      end
    end

    context 'when the request is invalid' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "symbol" => provider.symbol + ".IMPERIAL",
                        "name" => "Imperial College"
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
        post '/repositories', params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{"source"=>"system_email", "title"=>"Can't be blank"}, {"source"=>"system_email", "title"=>"Is invalid"}])
      end
    end
  end

  describe 'PUT /repositories/:id' do
    context 'when the record exists' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "name" => "Imperial College 2",
                        "clientType" => "periodical",
                        "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8" }} }
      end

      it 'updates the record' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College 2")
        expect(json.dig('data', 'attributes', 'globusUuid')).to eq("9908a164-1e4f-4c17-ae1b-cc318839d6c8")
        expect(json.dig('data', 'attributes', 'name')).not_to eq(client.name)
        expect(json.dig('data', 'attributes', 'clientType')).to eq("periodical")
      end
    end

    context 'removes the globus_uuid' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "globusUuid" => nil }} }
      end

      it 'updates the record' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("My data center")
        expect(json.dig('data', 'attributes', 'globusUuid')).to be_nil
      end
    end

    context 'invalid globus_uuid' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "globusUuid" => "abc" }} }
      end

      it 'updates the record' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"globus_uuid", "title"=>"Abc is not a valid UUID")
      end
    end

    context 'using basic auth', vcr: true do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "name" => "Imperial College 2"}} }
      end
      let(:credentials) { provider.encode_auth_param(username: provider.symbol.downcase, password: "12345") }
      let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials } }

      it 'updates the record' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("Imperial College 2")
        expect(json.dig('data', 'attributes', 'name')).not_to eq(client.name)
      end
    end

    context 'updating with ISSNs' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "name" => "Journal of Insignificant Results",
                        "clientType" => "periodical",
                        "issn" => { "electronic" => "1544-9173",
                                    "print" => "1545-7885" } }} }
      end

      it 'updates the record' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig('data', 'attributes', 'name')).to eq("Journal of Insignificant Results")
        expect(json.dig('data', 'attributes', 'name')).not_to eq(client.name)
        expect(json.dig('data', 'attributes', 'clientType')).to eq("periodical")
        expect(json.dig('data', 'attributes', 'issn')).to eq("electronic"=>"1544-9173", "print"=>"1545-7885")
      end
    end

    context 'when the request is invalid' do
      let(:params) do
        { "data" => { "type" => "repositories",
                      "attributes" => {
                        "symbol" => client.symbol + "M",
                        "email" => "bob@example.com",
                        "name" => "Imperial College"}} }
      end

      it 'returns status code 422' do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq("source"=>"symbol", "title"=>"Cannot be changed")
      end
    end
  end

  describe 'DELETE /clients/:id' do
    it 'returns status code 204' do
      delete "/repositories/#{client.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end

    context 'when the resource doesnt exist' do
      it 'returns status code 404' do
        delete '/repositories/xxx', nil, headers

        expect(last_response.status).to eq(404)
      end

      it 'returns a validation failure message' do
        delete '/repositories/xxx', nil, headers

        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe "doi transfer", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client) }
    let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET", name: "Target Client") }
    let(:params) do
      { "data" => { "type" => "repositories",
                    "attributes" => {
                      "targetId" => target.symbol }} }
    end

    before do
      Doi.import
      sleep 1
    end

    it 'returns status code 200' do
      put "/repositories/#{client.symbol}", params, headers
      sleep 1

      expect(last_response.status).to eq(200)
    end

    # it "transfered all DOIs" do
    #   expect(Doi.query(nil, client_id: client.symbol.downcase).results.total).to eq(0)
    #   expect(Doi.query(nil, client_id: target.symbol.downcase).results.total).to eq(3)
    # end
  end
end
