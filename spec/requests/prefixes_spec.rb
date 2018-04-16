require 'rails_helper'

describe "Prefixes", type: :request do
  # initialize test data
  let!(:prefixes)  { create_list(:prefix, 10) }
  let(:bearer) { User.generate_token }
  let(:prefix_id) { prefixes.first.prefix }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer }}

  # Test suite for GET /prefixes
  describe 'GET /prefixes' do
    # make HTTP get request before each example
    before { get '/prefixes', headers: headers }

    it 'returns prefixes' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /prefixes/:id
  describe 'GET /prefixes/:id' do
    before { get "/prefixes/#{prefix_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the prefix' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(prefix_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the prefix does not exist' do
      before { get "/prefixes/10.1234" , headers: headers}

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end

    context 'when the record does not exist' do
      before { get "/prefixes/xxx" , headers: headers}

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /prefixes' do
    context 'when the request is valid' do
      let!(:provider)  { create(:provider) }
      let(:valid_attributes) do
        {
          "data" => {
                    "type" => "prefixes",
                    "attributes" => {
                      "prefix" => "10.17177",
                      "id" => "10.17177"
                      }
            }
        }
      end

      before { post '/prefixes', params: valid_attributes.to_json, headers: headers }

      it 'creates a prefix' do
        expect(json.dig('data', 'id')).to eq("10.17177")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let!(:provider)  { create(:provider) }
      let(:not_valid_attributes) do
        {
          "data" => {
                    "type" => "prefixes",
                    "attributes" => {
                      "prefix" => "dsds10.33342"
                    }
            }
        }
      end

      before { post '/prefixes', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("source"=>"prefix", "title"=>"Can't be blank")
      end
    end
  end

  # # Test suite for PUT /prefixes/:id
  # Prefixes have no updates
  # describe 'PUT /prefixes/:id' do
  #   let!(:provider)  { create(:provider) }
  #   let(:valid_attributes) do
  #     {
  #       "data" => {
  #                 "id": "10.17177",
  #                 "type": "prefixes",
  #                 "attributes": {
  #                   "prefix": "10.17177"
  #                 }
  #         }
  #     }
  #   end
  #
  #   context 'when the record exists' do
  #     before { put "/prefixes/#{prefix_id}", params: valid_attributes.to_json , headers: headers}
  #
  #     it 'updates the record' do
  #       expect(response.body).not_to be_empty
  #     end
  #
  #     it 'returns status code 204' do
  #       expect(response).to have_http_status(200)
  #     end
  #   end
  # end

  # Test suite for DELETE /prefixes/:id
  describe 'DELETE /prefixes/:id' do
    before { delete "/prefixes/#{prefix_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
