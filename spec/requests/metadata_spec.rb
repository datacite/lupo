require 'rails_helper'

RSpec.describe "Metadata", type: :request  do
  # initialize test data
  let!(:metadata)  { create_list(:metadata, 10) }
  let(:metadata_id) { metadata.id }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN']}}

  # Test suite for GET /metadata
  describe 'GET /metadata' do
    # make HTTP get request before each example
    before { get '/metadata', headers: headers }

    it 'returns Metadata' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /metadata/:id
  describe 'GET /metadata/:id' do
    before { get "/metadata/#{metadata_id}", headers: headers }

    context 'when the record exists' do
      it 'returns the Metadata' do
        expect(json).not_to be_empty
        expect(json['data']['attributes']['url']).to eq(metadata.first.url)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:metadata_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        # expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /metadata
  describe 'POST /metadata' do
    # valid payload

    # let!(:doi_quota_used)  { datacenter.doi_quota_used }
    context 'when the request is valid' do
      let!(:dataset)  { create(:dataset) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
        			"dataset_id"=> dataset.uid,
        			"metadata_version"=> 4,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"xml"=> "<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"datacite-metadata-v2.0.xsd\" lastMetadataUpdate=\"2006-05-04\" metadataVersionNumber=\"1\"><identifier identifierType=\"DOI\"></identifier><creators><creator><creatorName>SeaZone Solutions Limited</creatorName></creator></creators><titles><title>England's Historic Seascapes: Demonstrating the Method</title></titles><publisher>Archaeology Data Service</publisher><publicationYear>2011</publicationYear><subjects><subject>Archaeology</subject></subjects><dates><date dateType=\"Created\">2009-04-01</date><date dateType=\"Created\">2011-02-01</date></dates><language>en</language><alternateIdentifiers><alternateIdentifier alternateIdentifierType=\"ADS Collection\">1036</alternateIdentifier></alternateIdentifiers><sizes><size>4 Text Reports</size></sizes><formats><format>PDF/A</format></formats><version>1</version><rights>http://archaeologydataservice.ac.uk/advice/termsOfUseAndAccess</rights><descriptions><description descriptionType=\"Other\">The HSC: Demonstrating the Method Project, funded by the ALSF, marks the initial implementation of a rigorous, repeatable methodology for Historic Seascape Characterisation, applying the principles already underpinning Historic Landscape Characterisation (HLC) to the coastal and marine zones.</description></descriptions></resource>"
        		}
          }
        }
      end
      before { post '/metadata', params: valid_attributes.to_json, headers: headers }

      it 'creates a Metadata' do

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
            "type" => "metadata",
            "attributes"=> {
        			"dataset_id"=> dataset.uid,
        			"metadata_version"=> 4,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"xml"=> "___"
        		}
          }
        }
      end
      before { post '/metadata', params: not_valid_attributes.to_json, headers: headers }


      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"xml", "title"=>"xml should be present")
      end
    end
  end

  # # Test suite for PUT /metadata/:id
  describe 'PUT /metadata/:id' do
    context 'when the record exists' do
      let!(:metadata)  { create(:metadata) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "id" => metadata.id,
            "attributes"=> {
        			"dataset_id"=> metadata.dataset_id,
        			"metadata_version"=> 29,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"xml"=> "<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"datacite-metadata-v2.0.xsd\" lastMetadataUpdate=\"2006-05-04\" metadataVersionNumber=\"1\"><identifier identifierType=\"DOI\"></identifier><creators><creator><creatorName>SeaZone Solutions Limited</creatorName></creator></creators><titles><title>England's Historic Seascapes: Demonstrating the Method</title></titles><publisher>Archaeology Data Service</publisher><publicationYear>2011</publicationYear><subjects><subject>Archaeology</subject></subjects><dates><date dateType=\"Created\">2009-04-01</date><date dateType=\"Created\">2011-02-01</date></dates><language>en</language><alternateIdentifiers><alternateIdentifier alternateIdentifierType=\"ADS Collection\">1036</alternateIdentifier></alternateIdentifiers><sizes><size>4 Text Reports</size></sizes><formats><format>PDF/A</format></formats><version>1</version><rights>http://archaeologydataservice.ac.uk/advice/termsOfUseAndAccess</rights><descriptions><description descriptionType=\"Other\">The HSC: Demonstrating the Method Project, funded by the ALSF, marks the initial implementation of a rigorous, repeatable methodology for Historic Seascape Characterisation, applying the principles already underpinning Historic Landscape Characterisation (HLC) to the coastal and marine zones.</description></descriptions></resource>"
        		}
          }
        }
      end
      before { put "/metadata/#{metadata_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
        puts json.inspect
        expect(response.body).not_to be_empty
        expect(json.dig('data', 'attributes', 'metadata_version')).to eq(29)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /metadata/:id
  describe 'DELETE /metadata/:id' do
    before { delete "/metadata/#{metadata_id}", headers: headers }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
