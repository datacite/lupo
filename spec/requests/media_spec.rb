require 'rails_helper'

describe "Media", type: :request, :order => :defined do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }
  let!(:medias)  { create_list(:media, 5, doi: doi) }
  let!(:media) { create(:media, doi: doi) }
  let(:bearer) { User.generate_token(role_id: "client_admin", provider_id: provider.symbol.downcase, client_id: client.symbol.downcase) }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}
  let(:media_type) { "application/xml" }
  let(:url) { "https://example.org" }

  describe 'GET /dois/DOI/media' do
    before { get "/dois/#{doi.doi}/media", headers: headers }

    it 'returns media' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(6)
      result = json['data'].first
      expect(result.dig("attributes", "media-type")).to eq("application/json")
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /media query by doi not found' do
    before { get "/dois/xxx/media", headers: headers }

    it 'returns media' do
      expect(json).not_to be_empty
      expect(json["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
    end

    it 'returns status code 404' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /dois/DOI/media/:id' do
    before { get "/dois/#{doi.doi}/media/#{media.uid}", headers: headers }

    context 'when the record exists' do
      it 'returns the media' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'id')).to eq(media.uid)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/dois/#{doi.doi}/media/xxxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /media' do
    context 'when the request is valid' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"media-type" => media_type,
              "url" => url
        		}
          }
        }
      end
      before { post "/dois/#{doi.doi}/media", params: valid_attributes.to_json, headers: headers }

      it 'creates a media record' do
        expect(json.dig('data', 'attributes', 'media-type')).to eq(media_type)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the media-type is missing' do
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
        			"media-type" => nil,
              "url" => url
        		}
          }
        }
      end
      before { post "/dois/#{doi.doi}/media", params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"media_type", "title"=>"Can't be blank"}])
      end
    end

    context 'when the media_type is not valid' do
      let(:media_type) { "text" }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
              "media-type"=> media_type,
              "url"=> url
            },
            "relationships"=>  {
              "doi"=>  {
                "data"=> {
                  "type"=> "dois",
                  "id"=> doi.doi
                }
              }
            }
          }
        }
      end
      before { post "/dois/#{doi.doi}/media", params: valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"media_type", "title"=>"Is invalid"}])
      end
    end
  end

  describe 'PATCH /dois/DOI/media/:id' do
    context 'when the request is valid' do
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
              "media-type"=> media_type,
              "url"=> url
            },
            "relationships"=>  {
              "doi"=>  {
                "data"=> {
                  "type"=> "dois",
                  "id"=> doi.doi
                }
              }
            }
          }
        }
      end

      before { patch "/dois/#{doi.doi}/media/#{media.uid}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        expect(json.dig('data', 'attributes', 'media-type')).to eq(media_type)
        expect(json.dig('data', 'attributes', 'url')).to eq(url)
        expect(json.dig('data', 'attributes', 'version')).to eq(1)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the request is invalid' do
      let(:url) { "mailto:info@example.org" }
      let(:params) do
        {
          "data" => {
            "type" => "media",
            "attributes"=> {
              "media-type"=> media_type,
              "url"=> url
            },
            "relationships"=>  {
              "doi"=>  {
                "data"=> {
                  "type"=> "dois",
                  "id"=> doi.doi
                }
              }
            }
          }
        }
      end

      before { patch "/dois/#{doi.doi}/media/#{media.uid}", params: params.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("source"=>"url", "title"=>"Is invalid")
      end
    end
  end

  describe 'DELETE /dois/DOI/media/:id' do
    before { delete "/dois/#{doi.doi}/media/#{media.uid}", headers: headers }

    context 'when the resources does exist' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end

    context 'when the resources doesnt exist' do
      before { delete "/dois/#{doi.doi}/media/xxx",  headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end
end
