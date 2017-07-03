require 'rails_helper'


RSpec.describe "Users", type: :request   do
  # initialize test data
  let!(:datacentres)  { create_list(:datacentre, 10) }
  let(:datacentre_id) { datacentres.first.symbol }
  anon_headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiQkwuSU1QRVJJQUwiLCJyb2xlIjoiYW5vbnltb3VzIn0.5jlyhcFKu0cZivuPjF5PE5bq9vdsBWOArZcz2sv6QgE'}
  admin_headers = {'ACCEPT'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json', 'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiQkwuSU1QRVJJQUwiLCJyb2xlIjoic3RhZmZfYWRtaW4ifQ.3ucWVKqV12QdEDcZDt9K_vYBH8dh90pU36c5QIkboaE'}

  # Test suite for GET /prefixes
  describe 'GET /datacentres Anon' do
    # make HTTP get request before each example
    before { get '/datacentres', headers: anon_headers }

    it 'returns datacentres' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /prefixes
  describe 'GET /datacentres Admin' do
    # make HTTP get request before each example
    before { get '/datacentres', headers: admin_headers }

    it 'returns datacentres' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

end
