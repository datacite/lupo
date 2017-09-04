require 'rails_helper'

RSpec.describe "Media", type: :request  do
  # initialize test data
  let!(:media)  { create_list(:media, 10) }
  let(:media_id) { media.first.id }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN']}}

  # Test suite for GET /media
  describe 'GET /media' do
    # make HTTP get request before each example
    before { get '/media', headers: headers }

    it 'returns Media' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /media/:id
  describe 'GET /media/:id' do
    before { get "/media/#{media_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the Media' do
        expect(json).not_to be_empty
        expect(json['data']['attributes']['url']).to eq(media.first.url)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:media_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /media
  describe 'POST /media' do
    # valid payload

    # let!(:doi_quota_used)  { datacenter.doi_quota_used }
    context 'when the request is valid' do
      let!(:dataset)  { create(:dataset) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"dataset_id"=> dataset.uid,
        			"version"=> 0,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"media_type"=> "application/pdf"
        		}
          }
        }
      end
      before { post '/media', params: valid_attributes.to_json, headers: headers }

      it 'creates a Media' do

        expect(json.dig('data', 'attributes', 'dataset-id')).to eq(dataset.uid)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
      end

      it 'Increase Quota' do
        # expect(doi_quota_used).to lt(datacenter.doi_quota_used)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      let!(:dataset)  { create(:dataset) }
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"dataset_id"=> dataset.uid,
        			"version"=> 0,
        			"url"=> "kjsdkjsdkjsd",
        			"media_type"=> "application/pdf"
        		}
          }
        }
      end
      before { post '/media', params: not_valid_attributes.to_json, headers: headers }


      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"url", "title"=>"Url Website should be an url")
      end
    end
  end

  # # Test suite for PUT /media/:id
  describe 'PUT /media/:id' do
    context 'when the record exists' do
      let!(:dataset)  { create(:dataset) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"dataset_id"=> dataset.uid,
        			"version"=> 0,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"media_type"=> "application/pdf"
        		}
          }
        }
      end
      before { put "/media/#{media_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /media/:id
  describe 'DELETE /media/:id' do
    before { delete "/media/#{media_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
