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
  let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + token } }

  describe 'GET /providers' do
    let!(:providers)  { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 1
    end

    it "returns providers" do
      get "/providers", nil, headers

      expect(json['data'].size).to eq(4)
      expect(json.dig('meta', 'total')).to eq(4)
    end

    it 'returns status code 200' do
      get "/providers", nil, headers

      expect(last_response.status).to eq(200)
    end
  end

  describe 'GET /providers/:id' do
    context 'when the record exists' do
      it 'returns the provider' do
        get "/providers/#{provider.symbol}", nil, headers

        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(provider.symbol.downcase)
      end

      it 'returns the provider info for member page' do
        get "/providers/#{provider.symbol}", nil, headers

        expect(json['data']['attributes']['twitterHandle']).to eq(provider.twitter_handle)
        expect(json['data']['attributes']['billingInformation']).to eq(provider.billing_information)
        expect(json['data']['attributes']['rorId']).to eq(provider.ror_id)
      end

      it 'returns status code 200' do
        get "/providers/#{provider.symbol}", nil, headers

        expect(last_response.status).to eq(200)
      end
    end

    context 'get provider type ROLE_CONTRACTUAL_PROVIDER and check it works ' do
      let(:provider)  { create(:provider, role_name: "ROLE_CONTRACTUAL_PROVIDER", name: "Contractor", symbol: "CONTRACT_SLASH") }

      it 'get provider' do
        get "/providers/#{provider.symbol.downcase}", nil, headers

        expect(json).not_to be_empty
        expect(json.dig('data', 'id')).to eq(provider.symbol.downcase)
      end

      it 'returns status code 200' do
        get "/providers/#{provider.symbol.downcase}", nil, headers

        expect(last_response.status).to eq(200)
      end
    end

    context 'when the record does not exist' do
      it 'returns status code 404' do
        get "/providers/xxx", nil, headers

        expect(last_response.status).to eq(404)
      end

      it 'returns a not found message' do
        get "/providers/xxx", nil, headers

        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end

    context "text/csv" do
      it 'returns status code 200' do
        get "/providers/", nil, { "HTTP_ACCEPT" => "text/csv", 'Authorization' => 'Bearer ' + token }
        
        expect(last_response.status).to eq(200)
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

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 201' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
      end
    end

    context 'request ability check' do
      let!(:providers)  { create_list(:provider, 2) }
      let(:last_provider_token) { User.generate_token(provider_id: providers.last.symbol, role_id:"provider_admin") }
      let(:headers_last) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Bearer ' + last_provider_token } }

      before do
        Provider.import
        sleep 1
      end

      it 'has no permission' do
        get "/providers/#{providers.first.symbol}", nil, headers_last

        expect(json["data"].dig('attributes', 'symbol')).to eq(providers.first.symbol)
        expect(json["data"].dig( 'attributes', 'billingInformation')).to eq(nil)
        expect(json["data"].dig( 'attributes', 'twitterHandle')).to eq(nil)
      end
    end

    context 'create provider member_role contractual_provider' do
      let(:params) do
        { "data" => { "type" => "providers",
                      "attributes" => {
                        "symbol" => "FG",
                        "name" => "Figshare",
                        "region" => "EMEA",
                        "contactEmail" => "doe@joe.joe",
                        "contactName" => "timAus",
                        "memberType" => "contractual_provider",
                        "country" => "GB" } } }
      end

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
        expect(json.dig('data', 'attributes', 'name')).to eq("Figshare")
        expect(json.dig('data', 'attributes', 'memberType')).to eq("contractual_provider")
      end

      it 'returns status code 201' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
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
              "twitterHandle"=>"@meekakitty",
              "rorId"=>"https://ror.org/05njkjr15",
              "billingInformation":{
                "city"=>"barcelona",
                "state"=>"Rennes",
                "country"=>"Rennes",
                "organization"=>"Rennes",
                "department"=>"Rennes",
                "address"=>"Rennes",
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

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("jkiritha@andrew.cmu.edu")
        expect(json.dig('data', 'attributes', 'billingInformation',"state")).to eq("Rennes")
        expect(json.dig('data', 'attributes', 'billingInformation',"postCode")).to eq("122dc")
        expect(json.dig('data', 'attributes', 'twitterHandle')).to eq("@meekakitty")
        expect(json.dig('data', 'attributes', 'rorId')).to eq("https://ror.org/05njkjr15")
      end

      it 'returns status code 201' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
      end
    end

    context 'request is valid with contact information' do
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
              "twitterHandle"=>"@eekakitty",
              "rorId"=>"https://ror.org/05njkjr15",
              "technicalContact"=> {
                "email"=> "kristian@example.com",
                "givenName"=> "Kristian",
                "familyName"=> "Garza"
              },
              "serviceContact"=> {
                "email"=> "martin@example.com",
                "givenName"=> "Martin",
                "familyName"=> "Fenner"
              },
              "billingContact"=> {
                "email"=> "Trisha@example.com",
                "givenName"=> "Trisha",
                "familyName"=> "cruse"
              },
              "secondaryBillingContact"=> {
                "email"=> "Trisha@example.com",
                "givenName"=> "Trisha",
                "familyName"=> "cruse"
              },
              "votingContact"=> {
                "email"=> "robin@example.com",
                "givenName"=> "Robin",
                "familyName"=> "Dasler"
              },
              "region"=>"",
              "symbol"=>"CMfddff33333dd111d111113f4d",
              "updated"=>"",
              "website"=>""
            }
          }
        }
      end

      it 'creates a provider' do
        post '/providers', params, headers
        
        expect(json.dig('data', 'attributes', 'technicalContact',"email")).to eq("kristian@example.com")
        expect(json.dig('data', 'attributes', 'technicalContact',"givenName")).to eq("Kristian")
        expect(json.dig('data', 'attributes', 'technicalContact',"familyName")).to eq("Garza")
        expect(json.dig('data', 'attributes', 'billingContact',"email")).to eq("Trisha@example.com")
        expect(json.dig('data', 'attributes', 'billingContact',"givenName")).to eq("Trisha")
        expect(json.dig('data', 'attributes', 'billingContact',"familyName")).to eq("cruse")
        expect(json.dig('data', 'attributes', 'secondaryBillingContact',"email")).to eq("Trisha@example.com")
        expect(json.dig('data', 'attributes', 'secondaryBillingContact',"givenName")).to eq("Trisha")
        expect(json.dig('data', 'attributes', 'secondaryBillingContact',"familyName")).to eq("cruse")
        expect(json.dig('data', 'attributes', 'serviceContact',"email")).to eq("martin@example.com")
        expect(json.dig('data', 'attributes', 'serviceContact',"givenName")).to eq("Martin")
        expect(json.dig('data', 'attributes', 'serviceContact',"familyName")).to eq("Fenner")
        expect(json.dig('data', 'attributes', 'votingContact',"email")).to eq("robin@example.com")
        expect(json.dig('data', 'attributes', 'votingContact',"givenName")).to eq("Robin")
        expect(json.dig('data', 'attributes', 'votingContact',"familyName")).to eq("Dasler")
      end

      it 'returns status code 201' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
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

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("jkiritha@andrew.cmu.edu")
      end

      it 'returns status code 200' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
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

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 200' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
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
      let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials } }

      it 'creates a provider' do
        post '/providers', params, headers

        expect(json.dig('data', 'attributes', 'contactEmail')).to eq("doe@joe.joe")
      end

      it 'returns status code 200' do
        post '/providers', params, headers

        expect(last_response.status).to eq(200)
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

      it 'returns status code 422' do
        post '/providers', params, headers

        expect(last_response.status).to eq(422)
      end

      it 'returns a validation failure message' do
        post '/providers', params, headers

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

      it 'returns status code 400' do
        post '/providers', params, headers

        expect(last_response.status).to eq(400)
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

      it 'updates the record' do
        put "/providers/#{provider.symbol}", params, headers

        expect(json.dig('data', 'attributes', 'contactName')).to eq("timAus")
      end

      it 'returns status code 200' do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(200)
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
      let(:headers) { {'HTTP_ACCEPT'=>'application/vnd.api+json', 'HTTP_AUTHORIZATION' => 'Basic ' + credentials } }

      it 'updates the record' do
        put "/providers/#{provider.symbol}", params, headers

        expect(json.dig('data', 'attributes', 'contactName')).to eq("timAus")
      end

      it 'returns status code 200' do
        put "/providers/#{provider.symbol}", params, headers

        expect(last_response.status).to eq(200)
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

      it 'returns status code 404' do
        put '/providers/xxx', params, headers

        expect(last_response.status).to eq(404)
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
