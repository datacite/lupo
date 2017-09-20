require 'rails_helper'

RSpec.describe "Media", type: :request  do
  # initialize test data
  let!(:media)  { create_list(:media, 5) }
  let(:media_id) { media.first.id }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN']}}

  # Test suite for GET /media
  describe 'GET /media' do
    # make HTTP get request before each example
    before { get '/media', headers: headers }

    it 'returns Media' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(5)
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
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The page you are looking for doesn't exist.")
      end
    end
  end

  # Test suite for POST /media
  describe 'POST /media' do
    # valid payload

    # let!(:doi_quota_used)  { client.doi_quota_used }
    context 'when the request is valid' do
      let!(:dataset)  { create(:dataset) }
      let(:doi)  { dataset.doi }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"version"=> 0,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"media_type"=> "application/pdf"
        		},
            "relationships"=>  {
              "dataset"=>  {
                "data"=> {
                  "type"=> "datasets",
                  "id"=>  doi
                }
              }
            }} }
      end
      before { post '/media', params: valid_attributes.to_json, headers: headers }

      it 'creates a Media' do
        expect(json.dig('data', 'attributes', 'dataset-id')).to eq(dataset.uid)
        expect(json.dig('data', 'attributes', 'url')).to eq("http://www.bl.uk/pdf/patspec.pdf")
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
        			"version"=> 0,
        			"url"=> "kjsdkjsdkjsd",
        			"media_type"=> "application/pdf"
        		},
            "relationships"=> {
              "dataset"=> {
                "data"=>{
                  "type"=>"datasets",
                  "id"=> dataset.uid
                }
              }
            }} }
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
      let!(:media_resource)  { create(:media) }
      let(:media_resource_id)  { media_resource.id }
      let(:media_resource_dataset_id)  { media_resource.dataset }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"version"=> 0,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf"
        		}
          }
        }
      end
      before { put "/media/#{media_resource_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(response.body).not_to be_empty
        expect(json.dig('data', 'attributes', 'media-type')).to eq(media_resource.media_type)
        expect(json.dig('data', 'attributes', 'url')).not_to eq(media_resource.url)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
    context 'when the request is invalid' do
      let!(:media_resource)  { create(:media) }
      let(:media_resource_id)  { media_resource.id }
      let(:media_resource_dataset_id)  { media_resource.dataset }
      let(:params) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"media_type"=> ""
        		}
          }
        }
      end

      before { put "/media/#{media_resource_id}", params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"media_type", "title"=>"Media type can't be blank")
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
  context 'when the resources doesnt exist' do
    before { delete '/media/xxx',  headers: headers }

    it 'returns status code 404' do
      expect(response).to have_http_status(404)
    end

    it 'returns a validation failure message' do
      expect(json["errors"].first).to eq("status"=>"404", "title"=>"The page you are looking for doesn't exist.")
    end
  end
end
