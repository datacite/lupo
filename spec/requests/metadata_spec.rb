require 'rails_helper'

describe "Metadata", type: :request  do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }
  let!(:metadatas)  { create_list(:metadata, 5, doi: doi) }
  let!(:metadata) { create(:metadata, doi: doi) }
  let(:bearer) { User.generate_token(role_id: "staff_admin") }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + bearer}}
  let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxyZXNvdXJjZSB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC0zIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTMvbWV0YWRhdGEueHNkIiB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTMiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyNTYvZjEwMDByZXNlYXJjaC44NTcwLnI2NDIwPC9pZGVudGlmaWVyPjxjcmVhdG9ycz48Y3JlYXRvcj48Y3JlYXRvck5hbWU+ZCBzPC9jcmVhdG9yTmFtZT48L2NyZWF0b3I+PC9jcmVhdG9ycz48dGl0bGVzPjx0aXRsZT5SZWZlcmVlIHJlcG9ydC4gRm9yOiBSRVNFQVJDSC0zNDgyIFt2ZXJzaW9uIDU7IHJlZmVyZWVzOiAxIGFwcHJvdmVkLCAxIGFwcHJvdmVkIHdpdGggcmVzZXJ2YXRpb25zXTwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5GMTAwMCBSZXNlYXJjaCBMaW1pdGVkPC9wdWJsaXNoZXI+PHB1YmxpY2F0aW9uWWVhcj4yMDE3PC9wdWJsaWNhdGlvblllYXI+PHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJUZXh0Ii8+PC9yZXNvdXJjZT4=" }

  describe 'GET /metadata' do
    before { get '/metadata', headers: headers }

    it 'returns Metadata' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(7)
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
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
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
        expect(json.dig('data', 'attributes', 'namespace')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the doi is missing' do
      # missing doi
      let(:not_valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
        			"xml"=> xml
        		}
          }
        }
      end
      before { post '/metadata', params: not_valid_attributes.to_json, headers: headers }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"doi", "title"=>"Doi must exist"}])
      end
    end

    context 'when the XML is not valid draft status' do
      let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwOi8vc2NoZW1hLmRhdGFjaXRlLm9yZy9tZXRhL2tlcm5lbC00L21ldGFkYXRhLnhzZCI+CiAgPGlkZW50aWZpZXIgaWRlbnRpZmllclR5cGU9IkRPSSI+MTAuNTQzOC80SzNNLU5ZVkc8L2lkZW50aWZpZXI+CiAgPGNyZWF0b3JzLz4KICA8dGl0bGVzPgogICAgPHRpdGxlPkVhdGluZyB5b3VyIG93biBEb2cgRm9vZDwvdGl0bGU+CiAgPC90aXRsZXM+CiAgPHB1Ymxpc2hlcj5EYXRhQ2l0ZTwvcHVibGlzaGVyPgogIDxwdWJsaWNhdGlvblllYXI+MjAxNjwvcHVibGljYXRpb25ZZWFyPgogIDxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iVGV4dCI+QmxvZ1Bvc3Rpbmc8L3Jlc291cmNlVHlwZT4KICA8YWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgICA8YWx0ZXJuYXRlSWRlbnRpZmllciBhbHRlcm5hdGVJZGVudGlmaWVyVHlwZT0iTG9jYWwgYWNjZXNzaW9uIG51bWJlciI+TVMtNDktMzYzMi01MDgzPC9hbHRlcm5hdGVJZGVudGlmaWVyPgogIDwvYWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgPHN1YmplY3RzPgogICAgPHN1YmplY3Q+ZGF0YWNpdGU8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5kb2k8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5tZXRhZGF0YTwvc3ViamVjdD4KICA8L3N1YmplY3RzPgogIDxkYXRlcz4KICAgIDxkYXRlIGRhdGVUeXBlPSJDcmVhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogICAgPGRhdGUgZGF0ZVR5cGU9Iklzc3VlZCI+MjAxNi0xMi0yMDwvZGF0ZT4KICAgIDxkYXRlIGRhdGVUeXBlPSJVcGRhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogIDwvZGF0ZXM+CiAgPHJlbGF0ZWRJZGVudGlmaWVycz4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJSZWZlcmVuY2VzIj4xMC41NDM4LzAwMTI8L3JlbGF0ZWRJZGVudGlmaWVyPgogICAgPHJlbGF0ZWRJZGVudGlmaWVyIHJlbGF0ZWRJZGVudGlmaWVyVHlwZT0iRE9JIiByZWxhdGlvblR5cGU9IlJlZmVyZW5jZXMiPjEwLjU0MzgvNTVFNS1UNUMwPC9yZWxhdGVkSWRlbnRpZmllcj4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJJc1BhcnRPZiI+MTAuNTQzOC8wMDAwLTAwU1M8L3JlbGF0ZWRJZGVudGlmaWVyPgogIDwvcmVsYXRlZElkZW50aWZpZXJzPgogIDx2ZXJzaW9uPjEuMDwvdmVyc2lvbj4KICA8ZGVzY3JpcHRpb25zPgogICAgPGRlc2NyaXB0aW9uIGRlc2NyaXB0aW9uVHlwZT0iQWJzdHJhY3QiPkVhdGluZyB5b3VyIG93biBkb2cgZm9vZCBpcyBhIHNsYW5nIHRlcm0gdG8gZGVzY3JpYmUgdGhhdCBhbiBvcmdhbml6YXRpb24gc2hvdWxkIGl0c2VsZiB1c2UgdGhlIHByb2R1Y3RzIGFuZCBzZXJ2aWNlcyBpdCBwcm92aWRlcy4gRm9yIERhdGFDaXRlIHRoaXMgbWVhbnMgdGhhdCB3ZSBzaG91bGQgdXNlIERPSXMgd2l0aCBhcHByb3ByaWF0ZSBtZXRhZGF0YSBhbmQgc3RyYXRlZ2llcyBmb3IgbG9uZy10ZXJtIHByZXNlcnZhdGlvbiBmb3IuLi48L2Rlc2NyaXB0aW9uPgogIDwvZGVzY3JpcHRpb25zPgo8L3Jlc291cmNlPgo=" }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
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

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'creates a metadata record' do
        expect(json.dig('data', 'attributes', 'xml')).to eq(xml)
        expect(json.dig('data', 'attributes', 'namespace')).to eq("http://datacite.org/schema/kernel-4")
      end
    end

    context 'when the XML is not valid findable status' do
      let(:doi) { create(:doi, client: client, aasm_state: "findable") }
      let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwOi8vc2NoZW1hLmRhdGFjaXRlLm9yZy9tZXRhL2tlcm5lbC00L21ldGFkYXRhLnhzZCI+CiAgPGlkZW50aWZpZXIgaWRlbnRpZmllclR5cGU9IkRPSSI+MTAuNTQzOC80SzNNLU5ZVkc8L2lkZW50aWZpZXI+CiAgPGNyZWF0b3JzLz4KICA8dGl0bGVzPgogICAgPHRpdGxlPkVhdGluZyB5b3VyIG93biBEb2cgRm9vZDwvdGl0bGU+CiAgPC90aXRsZXM+CiAgPHB1Ymxpc2hlcj5EYXRhQ2l0ZTwvcHVibGlzaGVyPgogIDxwdWJsaWNhdGlvblllYXI+MjAxNjwvcHVibGljYXRpb25ZZWFyPgogIDxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iVGV4dCI+QmxvZ1Bvc3Rpbmc8L3Jlc291cmNlVHlwZT4KICA8YWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgICA8YWx0ZXJuYXRlSWRlbnRpZmllciBhbHRlcm5hdGVJZGVudGlmaWVyVHlwZT0iTG9jYWwgYWNjZXNzaW9uIG51bWJlciI+TVMtNDktMzYzMi01MDgzPC9hbHRlcm5hdGVJZGVudGlmaWVyPgogIDwvYWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgPHN1YmplY3RzPgogICAgPHN1YmplY3Q+ZGF0YWNpdGU8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5kb2k8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5tZXRhZGF0YTwvc3ViamVjdD4KICA8L3N1YmplY3RzPgogIDxkYXRlcz4KICAgIDxkYXRlIGRhdGVUeXBlPSJDcmVhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogICAgPGRhdGUgZGF0ZVR5cGU9Iklzc3VlZCI+MjAxNi0xMi0yMDwvZGF0ZT4KICAgIDxkYXRlIGRhdGVUeXBlPSJVcGRhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogIDwvZGF0ZXM+CiAgPHJlbGF0ZWRJZGVudGlmaWVycz4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJSZWZlcmVuY2VzIj4xMC41NDM4LzAwMTI8L3JlbGF0ZWRJZGVudGlmaWVyPgogICAgPHJlbGF0ZWRJZGVudGlmaWVyIHJlbGF0ZWRJZGVudGlmaWVyVHlwZT0iRE9JIiByZWxhdGlvblR5cGU9IlJlZmVyZW5jZXMiPjEwLjU0MzgvNTVFNS1UNUMwPC9yZWxhdGVkSWRlbnRpZmllcj4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJJc1BhcnRPZiI+MTAuNTQzOC8wMDAwLTAwU1M8L3JlbGF0ZWRJZGVudGlmaWVyPgogIDwvcmVsYXRlZElkZW50aWZpZXJzPgogIDx2ZXJzaW9uPjEuMDwvdmVyc2lvbj4KICA8ZGVzY3JpcHRpb25zPgogICAgPGRlc2NyaXB0aW9uIGRlc2NyaXB0aW9uVHlwZT0iQWJzdHJhY3QiPkVhdGluZyB5b3VyIG93biBkb2cgZm9vZCBpcyBhIHNsYW5nIHRlcm0gdG8gZGVzY3JpYmUgdGhhdCBhbiBvcmdhbml6YXRpb24gc2hvdWxkIGl0c2VsZiB1c2UgdGhlIHByb2R1Y3RzIGFuZCBzZXJ2aWNlcyBpdCBwcm92aWRlcy4gRm9yIERhdGFDaXRlIHRoaXMgbWVhbnMgdGhhdCB3ZSBzaG91bGQgdXNlIERPSXMgd2l0aCBhcHByb3ByaWF0ZSBtZXRhZGF0YSBhbmQgc3RyYXRlZ2llcyBmb3IgbG9uZy10ZXJtIHByZXNlcnZhdGlvbiBmb3IuLi48L2Rlc2NyaXB0aW9uPgogIDwvZGVzY3JpcHRpb25zPgo8L3Jlc291cmNlPgo=" }

      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "attributes"=> {
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

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Creators Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator )."}])
      end
    end
  end

  describe 'DELETE /metadata/:id' do
    before { delete "/metadata/#{metadata.uid}", headers: headers }

    context 'when the resource does exist' do
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

  describe 'POST /metadata/validate' do
    let(:valid_attributes) do
      {
        "data" => {
          "type" => "metadata",
          "attributes"=> {
            "xml"=> xml
          }
        }
      }
    end

    before { post "/metadata/validate", params: valid_attributes.to_json, headers: headers }

    context 'when the metadata validate' do
      it 'shows a metadata record' do
        expect(json.dig('data', 'attributes', 'xml')).to eq(xml)
        expect(json.dig('data', 'attributes', 'namespace')).to eq("http://datacite.org/schema/kernel-3")
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the metadata don\'t validate' do
      let(:xml) { "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwOi8vc2NoZW1hLmRhdGFjaXRlLm9yZy9tZXRhL2tlcm5lbC00L21ldGFkYXRhLnhzZCI+CiAgPGlkZW50aWZpZXIgaWRlbnRpZmllclR5cGU9IkRPSSI+MTAuNTQzOC80SzNNLU5ZVkc8L2lkZW50aWZpZXI+CiAgPGNyZWF0b3JzLz4KICA8dGl0bGVzPgogICAgPHRpdGxlPkVhdGluZyB5b3VyIG93biBEb2cgRm9vZDwvdGl0bGU+CiAgPC90aXRsZXM+CiAgPHB1Ymxpc2hlcj5EYXRhQ2l0ZTwvcHVibGlzaGVyPgogIDxwdWJsaWNhdGlvblllYXI+MjAxNjwvcHVibGljYXRpb25ZZWFyPgogIDxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iVGV4dCI+QmxvZ1Bvc3Rpbmc8L3Jlc291cmNlVHlwZT4KICA8YWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgICA8YWx0ZXJuYXRlSWRlbnRpZmllciBhbHRlcm5hdGVJZGVudGlmaWVyVHlwZT0iTG9jYWwgYWNjZXNzaW9uIG51bWJlciI+TVMtNDktMzYzMi01MDgzPC9hbHRlcm5hdGVJZGVudGlmaWVyPgogIDwvYWx0ZXJuYXRlSWRlbnRpZmllcnM+CiAgPHN1YmplY3RzPgogICAgPHN1YmplY3Q+ZGF0YWNpdGU8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5kb2k8L3N1YmplY3Q+CiAgICA8c3ViamVjdD5tZXRhZGF0YTwvc3ViamVjdD4KICA8L3N1YmplY3RzPgogIDxkYXRlcz4KICAgIDxkYXRlIGRhdGVUeXBlPSJDcmVhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogICAgPGRhdGUgZGF0ZVR5cGU9Iklzc3VlZCI+MjAxNi0xMi0yMDwvZGF0ZT4KICAgIDxkYXRlIGRhdGVUeXBlPSJVcGRhdGVkIj4yMDE2LTEyLTIwPC9kYXRlPgogIDwvZGF0ZXM+CiAgPHJlbGF0ZWRJZGVudGlmaWVycz4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJSZWZlcmVuY2VzIj4xMC41NDM4LzAwMTI8L3JlbGF0ZWRJZGVudGlmaWVyPgogICAgPHJlbGF0ZWRJZGVudGlmaWVyIHJlbGF0ZWRJZGVudGlmaWVyVHlwZT0iRE9JIiByZWxhdGlvblR5cGU9IlJlZmVyZW5jZXMiPjEwLjU0MzgvNTVFNS1UNUMwPC9yZWxhdGVkSWRlbnRpZmllcj4KICAgIDxyZWxhdGVkSWRlbnRpZmllciByZWxhdGVkSWRlbnRpZmllclR5cGU9IkRPSSIgcmVsYXRpb25UeXBlPSJJc1BhcnRPZiI+MTAuNTQzOC8wMDAwLTAwU1M8L3JlbGF0ZWRJZGVudGlmaWVyPgogIDwvcmVsYXRlZElkZW50aWZpZXJzPgogIDx2ZXJzaW9uPjEuMDwvdmVyc2lvbj4KICA8ZGVzY3JpcHRpb25zPgogICAgPGRlc2NyaXB0aW9uIGRlc2NyaXB0aW9uVHlwZT0iQWJzdHJhY3QiPkVhdGluZyB5b3VyIG93biBkb2cgZm9vZCBpcyBhIHNsYW5nIHRlcm0gdG8gZGVzY3JpYmUgdGhhdCBhbiBvcmdhbml6YXRpb24gc2hvdWxkIGl0c2VsZiB1c2UgdGhlIHByb2R1Y3RzIGFuZCBzZXJ2aWNlcyBpdCBwcm92aWRlcy4gRm9yIERhdGFDaXRlIHRoaXMgbWVhbnMgdGhhdCB3ZSBzaG91bGQgdXNlIERPSXMgd2l0aCBhcHByb3ByaWF0ZSBtZXRhZGF0YSBhbmQgc3RyYXRlZ2llcyBmb3IgbG9uZy10ZXJtIHByZXNlcnZhdGlvbiBmb3IuLi48L2Rlc2NyaXB0aW9uPgogIDwvZGVzY3JpcHRpb25zPgo8L3Jlc291cmNlPgo=" }

      it 'shows errors' do
        expect(json["errors"]).to eq([{"source"=>"creators", "title"=>"Missing child element(s). Expected is ( {http://datacite.org/schema/kernel-4}creator )."}])
      end

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end
  end
end
