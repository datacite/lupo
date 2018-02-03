require 'rails_helper'

describe "Metadata", type: :request  do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }
  let!(:metadatas)  { create_list(:metadata, 5, doi: doi) }
  let!(:metadata) { create(:metadata, doi: doi) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}

  describe 'GET /metadata' do
    before { get '/metadata', headers: headers }

    it 'returns Metadata' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(6)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /metadata/:id' do
    before { get "/metadata/#{metadata.uid}", headers: headers }

    context 'when the record exists' do
      it 'returns the Metadata' do
        expect(json).not_to be_empty
        expect(json.dig('data', 'id')).to eq(metadata.uid)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/metadata/xxxx", headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end

  describe 'POST /metadata' do
    context 'when the request is valid' do
      let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48cmVzb3VyY2UgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM9Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IiB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTQvbWV0YWRhdGEueHNkIj48aWRlbnRpZmllciBpZGVudGlmaWVyVHlwZT0iRE9JIj4xMC4yNTQ5OS94dWRhMnB6cmFocm9lcXBlZnZucTV6dDZkYzwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPklhbiBQYXJyeTwvY3JlYXRvck5hbWU+PG5hbWVJZGVudGlmaWVyIHNjaGVtZVVSST0iaHR0cDovL29yY2lkLm9yZy8iIG5hbWVJZGVudGlmaWVyU2NoZW1lPSJPUkNJRCI+MDAwMC0wMDAxLTYyMDItNTEzWDwvbmFtZUlkZW50aWZpZXI+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+U3VibWl0dGVkIGNoZW1pY2FsIGRhdGEgZm9yIEluQ2hJS2V5PVlBUFFCWFFZTEpSWFNBLVVIRkZGQU9ZU0EtTjwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5Sb3lhbCBTb2NpZXR5IG9mIENoZW1pc3RyeTwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iRGF0YXNldCI+U3Vic3RhbmNlPC9yZXNvdXJjZVR5cGU+PHJpZ2h0c0xpc3Q+PHJpZ2h0cyByaWdodHNVUkk9Imh0dHBzOi8vY3JlYXRpdmVjb21tb25zLm9yZy9zaGFyZS15b3VyLXdvcmsvcHVibGljLWRvbWFpbi9jYzAvIj5ObyBSaWdodHMgUmVzZXJ2ZWQ8L3JpZ2h0cz48L3JpZ2h0c0xpc3Q+PC9yZXNvdXJjZT4=" }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
        			"namespace"=> "http://datacite.org/schema/kernel-4",
        			"xml"=> xml
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
      before { post '/metadata', params: valid_attributes.to_json, headers: headers }

      it 'creates a metadata record' do
        expect(json.dig('data', 'attributes', 'xml')).to eq(xml)
        expect(json.dig('data', 'attributes', 'version')).to eq(1)
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      # missing namespace
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
        			"xml"=> "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48cmVzb3VyY2UgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM9Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IiB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTQvbWV0YWRhdGEueHNkIj48aWRlbnRpZmllciBpZGVudGlmaWVyVHlwZT0iRE9JIj4xMC4yNTQ5OS94dWRhMnB6cmFocm9lcXBlZnZucTV6dDZkYzwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPklhbiBQYXJyeTwvY3JlYXRvck5hbWU+PG5hbWVJZGVudGlmaWVyIHNjaGVtZVVSST0iaHR0cDovL29yY2lkLm9yZy8iIG5hbWVJZGVudGlmaWVyU2NoZW1lPSJPUkNJRCI+MDAwMC0wMDAxLTYyMDItNTEzWDwvbmFtZUlkZW50aWZpZXI+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+U3VibWl0dGVkIGNoZW1pY2FsIGRhdGEgZm9yIEluQ2hJS2V5PVlBUFFCWFFZTEpSWFNBLVVIRkZGQU9ZU0EtTjwvYmxpc2hlcj5Sb3lhbCBTb2NpZXR5IG9mIENoZW1pc3RyeTwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iRGF0YXNldCI+U3Vic3RhbmNlPC9yZXNvdXJjZVR5cGU+PHJpZ2h0c0xpc3Q+PHJpZ2h0cyByaWdodHNVUkk9Imh0dHBzOi8vY3JlYXRpdmVjb21tb25zLm9yZy9zaGFyZS15b3VyLXdvcmsvcHVibGljLWRvbWFpbi9jYzAvIj5ObyBSaWdodHMgUmVzZXJ2ZWQ8L3JpZ2h0cz48L3JpZ2h0c0xpc3Q+PC9yZXNvdXJjZT4="
        		},
            "relationships"=>  {
              "doi"=>  {
                "data"=> {
                  "type"=> "dois",
                  "id"=>  doi.doi
                }
              }
            }
          }
        }
      end
      before { post '/metadata', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json).to eq("errors"=>[{"id"=>"namespace", "title"=>"Namespace can't be blank"}])
      end
    end
  end

  describe 'DELETE /metadata/:id' do
    before { delete "/metadata/#{metadata.uid}", headers: headers }

    context 'when the resources does exist' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end

    context 'when the resources doesnt exist' do
      before { delete '/metadata/xxx',  headers: headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end
end
