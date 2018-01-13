require 'rails_helper'

describe "dois", type: :request do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let!(:dois) { create_list(:doi, 10, client: client) }
  let(:doi) { create(:doi, client: client) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

  # Test suite for GET /dois
  describe 'GET /dois' do
    # make HTTP get request before each example
    before { get '/dois', headers: headers }

    it 'returns dois' do
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /dois/:id
  describe 'GET /dois/:id' do
    context 'when the record exists' do
      before { get "/dois/#{doi.doi}", headers: headers }

      it 'returns the Doi' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'attributes', 'doi')).to eq(doi.doi.downcase)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/dois/10.5256/xxxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json).to eq("errors"=>[{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
      end
    end
  end

  # Test suite for POST /dois
  describe 'POST /dois' do
    # valid payload

    context 'when the request is valid' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "version" => 1,
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> client.symbol.downcase
                }
              }
            }
          }
        }
      end
      before { post '/dois', params: valid_attributes.to_json, headers: headers }

      it 'creates a Doi' do
      expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      expect(json.dig('data', 'attributes', 'doi')).to eq("10.4122/10703")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.aaaa03",
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
              "version" => 1
            },
            "relationships"=> {
              "client"=>  {
                "data"=> {
                  "type"=> "clients",
                  "id"=> client.symbol.downcase
                }
              }
            }
          }
        }
      end
      before { post '/dois', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json).to eq("errors"=>[{"id"=>"doi", "title"=>"Doi is invalid"}])
      end
    end
  end

  # # Test suite for PUT /dois/:id
  describe 'PATCH /dois/:id' do
    context 'when the record exists' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.4122/10703",
              "url"=> "http://www.bl.uk/pdf/patspec.pdf",
              "version" => 3,
              "client_id"=> client.symbol
            }
          }
        }
      end
      before { patch "/dois/#{doi.doi}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /dois/:id
  describe 'DELETE /dois/:id' do
    before do
      doi = create(:doi, client: client, aasm_state: "draft")
      delete "/dois/#{doi.doi}", headers: headers
    end

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'deletes the record' do
      expect(response.body).to be_empty
    end
  end

  describe 'DELETE /dois/:id findable state' do
    before do
      doi = create(:doi, client: client, aasm_state: "findable")
      delete "/dois/#{doi.doi}", headers: headers
    end

    it 'returns status code 405' do
      expect(response).to have_http_status(405)
    end

    it 'deletes the record' do
      expect(json["errors"]).to eq([{"status"=>"405", "title"=>"Method not allowed"}])
    end
  end
end
