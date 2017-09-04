require 'rails_helper'

RSpec.describe "Metadata", type: :request  do
  # initialize test data
  let!(:metadata)  { create_list(:metadata, 10) }
  let(:metadata_id) { metadata.first.id }
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
        			"xml"=> "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxyZXNvdXJjZSB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTIuMiIgeG1sbnM6ZHNwYWNlPSJodHRwOi8vd3d3LmRzcGFjZS5vcmcveG1sbnMvZHNwYWNlL2RpbSIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtMi4yIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTIuMi9tZXRhZGF0YS54c2QiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyODYvZWRhdGEvMzkwOTwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPlRvb3RpbGwsIFBoaWxpcDwvY3JlYXRvck5hbWU+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+VGVzdCBub3RlYm9vayBmb3IgZGVtbzwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxjb250cmlidXRvcnM+PGNvbnRyaWJ1dG9yIGNvbnRyaWJ1dG9yVHlwZT0iRGF0YU1hbmFnZXIiPjxjb250cmlidXRvck5hbWU+U2NpZW5jZSBhbmQgVGVjaG5vbG9neSBGYWNpbGl0aWVzIENvdW5jaWw8L2NvbnRyaWJ1dG9yTmFtZT48L2NvbnRyaWJ1dG9yPjxjb250cmlidXRvciBjb250cmlidXRvclR5cGU9Ikhvc3RpbmdJbnN0aXR1dGlvbiI+PGNvbnRyaWJ1dG9yTmFtZT5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvY29udHJpYnV0b3JOYW1lPjwvY29udHJpYnV0b3I+PC9jb250cmlidXRvcnM+PGRhdGVzPjxkYXRlIGRhdGVUeXBlPSJJc3N1ZWQiPjIwMTctMDktMDQ8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IkF2YWlsYWJsZSI+MjAxNy0wOS0wNDwvZGF0ZT48ZGF0ZSBkYXRlVHlwZT0iSXNzdWVkIj4yMDE3LTA4LTc8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IlVwZGF0ZWQiPjIwMTctMDktMDQ8L2RhdGU+PC9kYXRlcz48cmVzb3VyY2VUeXBlIHJlc291cmNlVHlwZUdlbmVyYWw9IkRhdGFzZXQiPkRhdGFzZXQ8L3Jlc291cmNlVHlwZT48YWx0ZXJuYXRlSWRlbnRpZmllcnM+PGFsdGVybmF0ZUlkZW50aWZpZXIgYWx0ZXJuYXRlSWRlbnRpZmllclR5cGU9InVyaSI+aHR0cDovL3B1cmwub3JnL25ldC9lZGF0YTIvaGFuZGxlL2VkYXRhLzM5NDY8L2FsdGVybmF0ZUlkZW50aWZpZXI+PC9hbHRlcm5hdGVJZGVudGlmaWVycz48ZGVzY3JpcHRpb25zPjxkZXNjcmlwdGlvbiBkZXNjcmlwdGlvblR5cGU9IkFic3RyYWN0Ij5DdUggaXMgYSBtYXRlcmlhbCB0aGF0IGFwcGVhcnMgaW4gYSB3aWRlIGRpdmVyc2l0eSBvZiBjaXJjdW1zdGFuY2VzIHJhbmdpbmcgZnJvbSBjYXRhbHlzaXMgdG8gZWxlY3Ryb2NoZW1pc3RyeSB0byBvcmdhbmljIHN5bnRoZXNpcy4gVGhlcmUgYXJlIGJvdGggYXF1ZW91cyBhbmQgbm9uYXF1ZW91cyBzeW50aGV0aWMgcm91dGVzIHRvIEN1SCwgZWFjaCBvZiB3aGljaCBhcHBhcmVudGx5IGxlYWRzIHRvIGEgZGlmZmVyZW50IHByb2R1Y3QuIFdlIGRldmVsb3BlZCBzeW50aGV0aWMgbWV0aG9kb2xvZ2llcyB0aGF0IGVuYWJsZSBtdWx0aWdyYW0gcXVhbnRpdGllcyBvZiBDdUggdG8gYmUgcHJvZHVjZWQgYnkgYm90aCByb3V0ZXMgYW5kIGNoYXJhY3Rlcml6ZWQgZWFjaCBwcm9kdWN0IGJ5IGEgY29tYmluYXRpb24gb2Ygc3BlY3Ryb3Njb3BpYywgZGlmZnJhY3Rpb24gYW5kIGNvbXB1dGF0aW9uYWwgbWV0aG9kcy4gVGhlIHJlc3VsdHMgc2hvdyB0aGF0LCB3aGlsZSBhbGwgbWV0aG9kcyBmb3IgdGhlIHN5bnRoZXNpcyBvZiBDdUggcmVzdWx0IGluIHRoZSBzYW1lIGJ1bGsgcHJvZHVjdCwgdGhlIHN5bnRoZXRpYyBwYXRoIHRha2VuIGVuZ2VuZGVycyBkaWZmZXJpbmcgc3VyZmFjZSBwcm9wZXJ0aWVzLiBUaGUgZGlmZmVyZW50IGJlaGF2aW9ycyBvZiBDdUggb2J0YWluZWQgYnkgYXF1ZW91cyBhbmQgbm9uYXF1ZW91cyByb3V0ZXMgY2FuIGJlIGFzY3JpYmVkIHRvIGEgY29tYmluYXRpb24gb2YgdmVyeSBkaWZmZXJlbnQgcGFydGljbGUgc2l6ZSBhbmQgZGlzc2ltaWxhciBzdXJmYWNlIHRlcm1pbmF0aW9uLCBuYW1lbHksIGJvbmRlZCBoeWRyb3h5bHMgZm9yIHRoZSBhcXVlb3VzIHJvdXRlcyBhbmQgYSBjb29yZGluYXRlZCBkb25vciBmb3IgdGhlIG5vbmFxdWVvdXMgcm91dGVzLiBUaGlzIHdvcmsgcHJvdmlkZXMgYSBwYXJ0aWN1bGFybHkgY2xlYXIgZXhhbXBsZSBvZiBob3cgdGhlIG5hdHVyZSBvZiBhbiBhZHNvcmJlZCBsYXllciBvbiBhIG5hbm9wYXJ0aWNsZSBzdXJmYWNlIGRldGVybWluZXMgdGhlIHByb3BlcnRpZXMuPC9kZXNjcmlwdGlvbj48L2Rlc2NyaXB0aW9ucz48L3Jlc291cmNlPg0K"
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
        			"xml"=> "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxyZXNvdXJjZSB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTIuMiIgeG1sbnM6ZHNwYWNlPSJodHRwOi8vd3d3LmRzcGFjZS5vcmcveG1sbnMvZHNwYWNlL2RpbSIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtMi4yIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTIuMi9tZXRhZGF0YS54c2QiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyODYvZWRhdGEvMzkwOTwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPlRvb3RpbGwsIFBoaWxpcDwvY3JlYXRvck5hbWU+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+VGVzdCBub3RlYm9vayBmb3IgZGVtbzwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxjb250cmlidXRvcnM+PGNvbnRyaWJ1dG9yIGNvbnRyaWJ1dG9yVHlwZT0iRGF0YU1hbmFnZXIiPjxjb250cmlidXRvck5hbWU+U2NpZW5jZSBhbmQgVGVjaG5vbG9neSBGYWNpbGl0aWVzIENvdW5jaWw8L2NvbnRyaWJ1dG9yTmFtZT48L2NvbnRyaWJ1dG9yPjxjb250cmlidXRvciBjb250cmlidXRvclR5cGU9Ikhvc3RpbmdJbnN0aXR1dGlvbiI+PGNvbnRyaWJ1dG9yTmFtZT5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvY29udHJpYnV0b3JOYW1lPjwvY29udHJpYnV0b3I+PC9jb250cmlidXRvcnM+PGRhdGVzPjxkYXRlIGRhdGVUeXBlPSJJc3N1ZWQiPjIwMTctMDktMDQ8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IkF2YWlsYWJsZSI+MjAxNy0wOS0wNDwvZGF0ZT48ZGF0ZSBkYXRlVHlwZT0iSXNzdWVkIj4yMDE3LTA4LTc8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IlVwZGF0ZWQiPjIwMTctMDktMDQ8L2RhdGU+PC9kYXRlcz48cmVzb3VyY2VUeXBlIHJlc291cmNlVHlwZUdlbmVyYWw9IkRhdGFzZXQiPkRhdGFzZXQ8L3Jlc291cmNlVHlwZT48YWx0ZXJuYXRlSWRlbnRpZmllcnM+PGFsdGVybmF0ZUlkZW50aWZpZXIgYWx0ZXJuYXRlSWRlbnRpZmllclR5cGU9InVyaSI+aHR0cDovL3B1cmwub3JnL25ldC9lZGF0YTIvaGFuZGxlL2VkYXRhLzM5NDY8L2FsdGVybmF0ZUlkZW50aWZpZXI+PC9hbHRlcm5hdGVJZGVudGlmaWVycz48ZGVzY3JpcHRpb25zPjxkZXNjcmlwdGlvbiBkZXNjcmlwdGlvblR5cGU9IkFic3RyYWN0Ij5DdUggaXMgYSBtYXRlcmlhbCB0aGF0IGFwcGVhcnMgaW4gYSB3aWRlIGRpdmVyc2l0eSBvZiBjaXJjdW1zdGFuY2VzIHJhbmdpbmcgZnJvbSBjYXRhbHlzaXMgdG8gZWxlY3Ryb2NoZW1pc3RyeSB0byBvcmdhbmljIHN5bnRoZXNpcy4gVGhlcmUgYXJlIGJvdGggYXF1ZW91cyBhbmQgbm9uYXF1ZW91cyBzeW50aGV0aWMgcm91dGVzIHRvIEN1SCwgZWFjaCBvZiB3aGljaCBhcHBhcmVudGx5IGxlYWRzIHRvIGEgZGlmZmVyZW50IHByb2R1Y3QuIFdlIGRldmVsb3BlZCBzeW50aGV0aWMgbWV0aG9kb2xvZ2llcyB0aGF0IGVuYWJsZSBtdWx0aWdyYW0gcXVhbnRpdGllcyBvZiBDdUggdG8gYmUgcHJvZHVjZWQgYnkgYm90aCByb3V0ZXMgYW5kIGNoYXJhY3Rlcml6ZWQgZWFjaCBwcm9kdWN0IGJ5IGEgY29tYmluYXRpb24gb2Ygc3BlY3Ryb3Njb3BpYywgZGlmZnJhY3Rpb24gYW5kIGNvbXB1dGF0aW9uYWwgbWV0aG9kcy4gVGhlIHJlc3VsdHMgc2hvdyB0aGF0LCB3aGlsZSBhbGwgbWV0aG9kcyBmb3IgdGhlIHN5bnRoZXNpcyBvZiBDdUggcmVzdWx0IGluIHRoZSBzYW1lIGJ1bGsgcHJvZHVjdCwgdGhlIHN5bnRoZXRpYyBwYXRoIHRha2VuIGVuZ2VuZGVycyBkaWZmZXJpbmcgc3VyZmFjZSBwcm9wZXJ0aWVzLiBUaGUgZGlmZmVyZW50IGJlaGF2aW9ycyBvZiBDdUggb2J0YWluZWQgYnkgYXF1ZW91cyBhbmc2ltaWxhciBzdXJmYWNlIHRlcm1pbmF0aW9uLCBuYW1lbHksIGJvbmRlZCBoeWRyb3h5bHMgZm9yIHRoZSBhcXVlb3VzIHJvdXRlcyBhbmQgYSBjb29yZGluYXRlZCBkb25vciBmb3IgdGhlIG5vbmFxdWVvdXMgcm91dGVzLiBUaGlzIHdvcmsgcHJvdmlkZXMgYSBwYXJ0aWN1bGFybHkgY2xlYXIgZXhhbXBsZSBvZiBob3cgdGhlIG5hdHVyZSBvZiBhbiBhZHNvcmJlZCBsYXllciBvbiBhIG5hbm9wYXJ0aWNsZSBzdXJmYWNlIGRldGVybWluZXMgdGhlIHByb3BlcnRpZXMuPC9kZXNjcmlwdGlvbj48L2Rlc2NyaXB0aW9ucz48L3Jlc291cmNlPg0K"
        		}
          }
        }
      end
      before { post '/metadata', params: not_valid_attributes.to_json, headers: headers }


      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json["errors"].first).to eq("id"=>"xml", "title"=>"Xml Your XML is wrong mate!!")
      end
    end
  end

  # # Test suite for PUT /metadata/:id
  describe 'PUT /metadata/:id' do
    context 'when the record exists' do
      let!(:metadata)  { create(:metadata) }
      let(:metadata_id)  { metadata.id }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "metadata",
            "id" => metadata.id,
            "attributes"=> {
        			"dataset_id"=> metadata.dataset_id,
        			"metadata_version"=> 29,
        			"url"=> "http://www.bl.uk/pdf/patspec.pdf",
        			"xml"=> "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxyZXNvdXJjZSB4bWxucz0iaHR0cDovL2RhdGFjaXRlLm9yZy9zY2hlbWEva2VybmVsLTIuMiIgeG1sbnM6ZHNwYWNlPSJodHRwOi8vd3d3LmRzcGFjZS5vcmcveG1sbnMvZHNwYWNlL2RpbSIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtMi4yIGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTIuMi9tZXRhZGF0YS54c2QiPjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUyODYvZWRhdGEvMzkwOTwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPlRvb3RpbGwsIFBoaWxpcDwvY3JlYXRvck5hbWU+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+VGVzdCBub3RlYm9vayBmb3IgZGVtbzwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxjb250cmlidXRvcnM+PGNvbnRyaWJ1dG9yIGNvbnRyaWJ1dG9yVHlwZT0iRGF0YU1hbmFnZXIiPjxjb250cmlidXRvck5hbWU+U2NpZW5jZSBhbmQgVGVjaG5vbG9neSBGYWNpbGl0aWVzIENvdW5jaWw8L2NvbnRyaWJ1dG9yTmFtZT48L2NvbnRyaWJ1dG9yPjxjb250cmlidXRvciBjb250cmlidXRvclR5cGU9Ikhvc3RpbmdJbnN0aXR1dGlvbiI+PGNvbnRyaWJ1dG9yTmFtZT5TY2llbmNlIGFuZCBUZWNobm9sb2d5IEZhY2lsaXRpZXMgQ291bmNpbDwvY29udHJpYnV0b3JOYW1lPjwvY29udHJpYnV0b3I+PC9jb250cmlidXRvcnM+PGRhdGVzPjxkYXRlIGRhdGVUeXBlPSJJc3N1ZWQiPjIwMTctMDktMDQ8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IkF2YWlsYWJsZSI+MjAxNy0wOS0wNDwvZGF0ZT48ZGF0ZSBkYXRlVHlwZT0iSXNzdWVkIj4yMDE3LTA4LTc8L2RhdGU+PGRhdGUgZGF0ZVR5cGU9IlVwZGF0ZWQiPjIwMTctMDktMDQ8L2RhdGU+PC9kYXRlcz48cmVzb3VyY2VUeXBlIHJlc291cmNlVHlwZUdlbmVyYWw9IkRhdGFzZXQiPkRhdGFzZXQ8L3Jlc291cmNlVHlwZT48YWx0ZXJuYXRlSWRlbnRpZmllcnM+PGFsdGVybmF0ZUlkZW50aWZpZXIgYWx0ZXJuYXRlSWRlbnRpZmllclR5cGU9InVyaSI+aHR0cDovL3B1cmwub3JnL25ldC9lZGF0YTIvaGFuZGxlL2VkYXRhLzM5NDY8L2FsdGVybmF0ZUlkZW50aWZpZXI+PC9hbHRlcm5hdGVJZGVudGlmaWVycz48ZGVzY3JpcHRpb25zPjxkZXNjcmlwdGlvbiBkZXNjcmlwdGlvblR5cGU9IkFic3RyYWN0Ij5DdUggaXMgYSBtYXRlcmlhbCB0aGF0IGFwcGVhcnMgaW4gYSB3aWRlIGRpdmVyc2l0eSBvZiBjaXJjdW1zdGFuY2VzIHJhbmdpbmcgZnJvbSBjYXRhbHlzaXMgdG8gZWxlY3Ryb2NoZW1pc3RyeSB0byBvcmdhbmljIHN5bnRoZXNpcy4gVGhlcmUgYXJlIGJvdGggYXF1ZW91cyBhbmQgbm9uYXF1ZW91cyBzeW50aGV0aWMgcm91dGVzIHRvIEN1SCwgZWFjaCBvZiB3aGljaCBhcHBhcmVudGx5IGxlYWRzIHRvIGEgZGlmZmVyZW50IHByb2R1Y3QuIFdlIGRldmVsb3BlZCBzeW50aGV0aWMgbWV0aG9kb2xvZ2llcyB0aGF0IGVuYWJsZSBtdWx0aWdyYW0gcXVhbnRpdGllcyBvZiBDdUggdG8gYmUgcHJvZHVjZWQgYnkgYm90aCByb3V0ZXMgYW5kIGNoYXJhY3Rlcml6ZWQgZWFjaCBwcm9kdWN0IGJ5IGEgY29tYmluYXRpb24gb2Ygc3BlY3Ryb3Njb3BpYywgZGlmZnJhY3Rpb24gYW5kIGNvbXB1dGF0aW9uYWwgbWV0aG9kcy4gVGhlIHJlc3VsdHMgc2hvdyB0aGF0LCB3aGlsZSBhbGwgbWV0aG9kcyBmb3IgdGhlIHN5bnRoZXNpcyBvZiBDdUggcmVzdWx0IGluIHRoZSBzYW1lIGJ1bGsgcHJvZHVjdCwgdGhlIHN5bnRoZXRpYyBwYXRoIHRha2VuIGVuZ2VuZGVycyBkaWZmZXJpbmcgc3VyZmFjZSBwcm9wZXJ0aWVzLiBUaGUgZGlmZmVyZW50IGJlaGF2aW9ycyBvZiBDdUggb2J0YWluZWQgYnkgYXF1ZW91cyBhbmQgbm9uYXF1ZW91cyByb3V0ZXMgY2FuIGJlIGFzY3JpYmVkIHRvIGEgY29tYmluYXRpb24gb2YgdmVyeSBkaWZmZXJlbnQgcGFydGljbGUgc2l6ZSBhbmQgZGlzc2ltaWxhciBzdXJmYWNlIHRlcm1pbmF0aW9uLCBuYW1lbHksIGJvbmRlZCBoeWRyb3h5bHMgZm9yIHRoZSBhcXVlb3VzIHJvdXRlcyBhbmQgYSBjb29yZGluYXRlZCBkb25vciBmb3IgdGhlIG5vbmFxdWVvdXMgcm91dGVzLiBUaGlzIHdvcmsgcHJvdmlkZXMgYSBwYXJ0aWN1bGFybHkgY2xlYXIgZXhhbXBsZSBvZiBob3cgdGhlIG5hdHVyZSBvZiBhbiBhZHNvcmJlZCBsYXllciBvbiBhIG5hbm9wYXJ0aWNsZSBzdXJmYWNlIGRldGVybWluZXMgdGhlIHByb3BlcnRpZXMuPC9kZXNjcmlwdGlvbj48L2Rlc2NyaXB0aW9ucz48L3Jlc291cmNlPg0K"
        		}
          }
        }
      end
      before { put "/metadata/#{metadata_id}", params: valid_attributes.to_json, headers: headers }

      it 'updates the record' do
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
