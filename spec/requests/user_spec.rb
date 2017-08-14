require 'rails_helper'

RSpec.describe "Users", type: :request   do
  # initialize test data
  let!(:datacenters)  { create_list(:datacenter, 10) }
  let(:datacenter) { create(:datacenter) }
  let(:headers) { {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer ' + ENV['JWT_TOKEN'] } }


  # Test suite for GET /prefixes
  describe 'GET /datacenters Anon' do
    before { get '/data-centers' }

    it 'returns datacenters' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(25)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /prefixes
  describe 'GET /datacenters Admin' do
    # make HTTP get request before each example
    before { get '/data-centers', headers: headers }

    it 'returns datacenters' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(25)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

end
