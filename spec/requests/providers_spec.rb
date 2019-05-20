require 'rails_helper'

describe "Providers", type: :request, elasticsearch: true  do
  let!(:provider) { create(:provider) }
  let(:token) { User.generate_token }
  let(:params) do
    { "data" => { "type" => "providers",
                  "attributes" => {
                    "symbol" => "BL",
                    "name" => "British Library",
                    "contactEmail" => "bob@example.com",
                    "country" => "GB" } } }
  end
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + token } }

  describe 'GET /providers' do
    let!(:providers)  { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 1
      get '/providers', headers: headers
    end

    it 'returns providers' do
      expect(json['data'].size).to eq(4)
      expect(json.dig('meta', 'total')).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /providers/:id' do
    before { get "/providers/#{provider.symbol}" , headers: headers}
    
    context 'when the record exists' do
      it 'returns the provider' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(provider.symbol.downcase)
      end

      it 'returns the provider info for member page' do
        expect(json['data']['attributes']['twitterHandle']).to eq(provider.twitter_handle)
        expect(json['data']['attributes']['billingInformation']).to eq(provider.billing_information)
        expect(json['data']['attributes']['rorId']).to eq(provider.ror_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'create provider type ROLE_CONTRACTUAL_PROVIDER and check it works ' do
      let(:provider)  { create(:provider, role_name: "ROLE_CONTRACTUAL_PROVIDER", name: "Contractor", symbol: "CONTRACT_SLASH") }


      before do 
        get "/providers/#{provider.symbol.downcase}", headers: headers 
      end

      it 'creates a provider' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(provider.symbol.downcase)
      end

      it 'returns status code 201' do
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

    context "text/csv" do
      before { get "/providers/", headers: { "HTTP_ACCEPT" => "text/csv", 'Authorization' => 'Bearer ' + token  } }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
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
                        "contactEmail" => "doe@joe.joe",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end

      before do 
        post '/providers', params: params.to_json, headers: headers 
      end

      it 'creates a provider' do
        puts json
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
    end

    context 'request ability check' do
      let!(:providers)  { create_list(:provider, 2) }
      let(:last_provider_token) { User.generate_token(provider_id: providers.last.symbol, role_id:"provider_admin") }
      let(:headers_last) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + last_provider_token } }


      before do
        Provider.import
        sleep 1
        get "/providers/#{providers.first.symbol}", headers: headers_last
      end
  

      it 'has no permission' do
        expect(json["data"].dig('attributes', 'symbol')).to eq(providers.first.symbol)
        expect(json["data"].dig( 'attributes', 'billingInformation')).to eq(nil)
        expect(json["data"].dig( 'attributes', 'twitterHandle')).to eq(nil)
      end
    end
    
    context 'create provider type ROLE_CONTRACTUAL_PROVIDER ' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "FG",
                        "name" => "Figshare",
                        "region" => "EMEA",
                        "contactEmail" => "doe@joe.joe",
                        "contactName" => "timAus",
                        "roleName" => "ROLE_CONTRACTUAL_PROVIDER",
                        "country" => "GB" } } }
      end

      before do 
        post '/providers', params: params.to_json, headers: headers 
      end

      it 'creates a provider' do
        puts json
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
        expect(json.dig('data', 'attributes', 'name')).to eq("Figshare")
      end

      it 'provider model get computed' do
        report = Provider.where(symbol: json.dig('data', 'attributes','symbol')).first
        expect(report.role_name).to eq("ROLE_CONTRACTUAL_PROVIDER")
        expect(report.member_type).to eq("contractual_provider")
        expect(report.member_type_label).to eq("Contractual Provider")      
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
    end



    context 'request is valid with billing information' do
      let(:params) do
        {
          "data"=>{
            "type"=>"providers",
            "attributes"=>{
              "contactEmail"=>"jkiritha@andrew.cmu.edu",
              "contactName"=>"Jonathan Kiritharan",
              "country"=>"US",
              "created"=>"",
              "description"=>"",
              "focusArea"=>"general",
              "hasPassword"=>"[FILTERED]",
              "isActive"=>true,
              "joined"=>"",
              "keepPassword"=>"[FILTERED]",
              "logoUrl"=>"",
              "name"=>"Carnegie Mellon University",
              "organizationType"=>"academicInstitution",
              "passwordInput"=>"[FILTERED]",
              "phone"=>"",
              "twitterHandle"=>"meekakitty",
              "rorId"=>"https://ror.org/05njkjr15",
              "billingInformation":{
                "city"=>"barcelona",
                "state"=>"Rennes",
                "postCode"=>"122dc"
              },
              "region"=>"",
              "symbol"=>"CMfddff33333dd111d111113f4d",
              "updated"=>"",
              "website"=>""
            }
          }
        }
      end

      before do 
        post '/providers', params: params.to_json, headers: headers 
      end

      it 'creates a provider' do
        puts json
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("jkiritha@andrew.cmu.edu")
        expect(json.dig('data', 'attributes', 'billingInformation',"state")).to eq("Rennes")
        expect(json.dig('data', 'attributes', 'billingInformation',"postCode")).to eq("122dc")
        expect(json.dig('data', 'attributes', 'twitterHandle')).to eq("meekakitty")
        expect(json.dig('data', 'attributes', 'rorId')).to eq("https://ror.org/05njkjr15")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
    end

    context 'request for admin provider with meta' do
      let(:params) do
        {
          "data" => {
            "attributes" => {
              "meta" => {
                "clients" => [{
                  "id" => "2019",
                  "title" => "2019",
                  "count" => 1
                }],
                "dois" => []
              }, "name" => "Carnegie Mellon University",
              "symbol" => "CMU", "description" => nil,
              "region" => "AMER", "country" => "US",
              "organizationType" => "academicInstitution",
              "focusArea" => "general", "logoUrl" => "",
              "contactName" => "Jonathan Kiritharan",
              "contactEmail" => "jkiritha@andrew.cmu.edu",
              "phone" => "", "website" => "", "isActive" => true,
              "passwordInput" => "@change", "hasPassword" => false,
              "keepPassword" => false, "joined" => ""
            }, "type" => "providers"
          }
        }

      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("jkiritha@andrew.cmu.edu")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

    end

    context 'request for admin provider' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "ADMIN",
                        "name" => "Admin",
                        "region" => "EMEA",
                        "contactEmail" => "doe@joe.joe",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end
      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'request uses basic auth' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "BL",
                        "name" => "British Library",
                        "region" => "EMEA",
                        "contactEmail" => "doe@joe.joe",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end
      let(:admin) { create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345") }
      let(:credentials) { admin.encode_auth_param(username: "ADMIN", password: "12345") }
      let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Basic ' + credentials } }

      before { post '/providers', params: params.to_json, headers: headers }

      it 'creates a provider' do
        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the request is missing a required attribute' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "BL",
                        "name" => "British Library",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("source"=>"contact_email", "title"=>"Can't be blank")
      end
    end

    context 'when the request is missing a data object' do
      let(:params) do
        { "type" => "providers",
          "attributes" => {
            "symbol" => "BL",
            "contactName" => "timAus",
            "name" => "British Library",
            "country" => "GB" } }
      end

      before { post '/providers', params: params.to_json, headers: headers }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
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
                        "contactEmail" => "Pepe@mdm.cod",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end
      before { put "/providers/#{provider.symbol}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'contactName')).to eq("timAus")
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
                        "contactEmail" => "Pepe@mdm.cod",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end
      let(:admin) { create(:provider, symbol: "ADMIN", role_name: "ROLE_ADMIN", password_input: "12345") }
      let(:credentials) { admin.encode_auth_param(username: "ADMIN", password: "12345") }
      let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Basic ' + credentials } }

      before { put "/providers/#{provider.symbol}", params: params.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'contactName')).to eq("timAus")
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
                        "contactEmail" => "Pepe@mdm.cod",
                        "contactName" => "timAus",
                        "country" => "GB" } } }
      end

      before { put '/providers/xxx', params: params.to_json, headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  # # Test suite for DELETE /providers/:id
  # describe 'DELETE /providers/:id' do
  #   before { delete "/providers/#{provider.symbol}", headers: headers }

  #   it 'returns status code 204' do
  #     expect(response).to have_http_status(204)
  #   end
  #   context 'when the resources doesnt exist' do
  #     before { delete '/providers/xxx', params: params.to_json, headers: headers }

  #     it 'returns status code 404' do
  #       expect(response).to have_http_status(404)
  #     end

  #     it 'returns a validation failure message' do
  #       expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
  #     end
  #   end
  # end

  # describe 'POST /providers/set-test-prefix' do
  #   before { post '/providers/set-test-prefix', headers: headers }

  #   it 'returns success' do
  #     expect(json['message']).to eq("Test prefix added.")
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end
end
