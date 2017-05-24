require 'rails_helper'

# RSpec.describe "Datacenters", type: :request, vcr: true do
#
#   let!(:datacenters) { create_list(:datacenter, 10) }
#   let(:datacenter_id) { datacenters.first.id }
#
#
#   describe "GET /datacentres" do
#     it "works! (now write some real specs)" do
#       get datacentres_path
#       expect(response).to have_http_status(200)
#     end
#
#
#
#     it "List Datacenters" do
#       datacenters = Datacenter.all[:data]
#       # expect(datacenters.length).to eq(39)
#       # member = datacenters.first
#       # expect(datacenters.name).to eq("Australian National Data Service")
#       expect(datacenters).to match_array([])
#     end
#
#     it "List Datacenter" do
#       datacenter = Datacenter.find(symbol: "datacite.datacite")[:data]
#       expect(datacenter.name).to eq("Datacite")
#     end
#
#     it "Create Datacenter" do
#       # For reference https://vimeo.com/97945495
#       datacenter = Datacenter.new(symbol: "Western.UB", name: "60 Hudson Street")
#       expect(datacenter.name).to eq("60 Hudson Street")
#     end
#
#     it "Edit Datacenter" do
#       datacenter = Datacenter.find(symbol: "Western.UB")[:data]
#       datacenter.update!(name: "32 Avenue of the Americas")
#       expect(datacenter.name).to eq("32 Avenue of the Americas")
#     end
#
#     it "Delete Datacenter" do
#       deleted = Datacenter.destroy(symbol: "Western.UB")[:data]
#       expect(response).to have_http_status(:ok)
#       datacenter = Datacenter.find(symbol: "Western.UB")[:data]
#       expect(datacenter).to match_array([])
#     end
#
#
#
#
#   end
# end



RSpec.describe 'Datacenters', type: :request, vcr: true  do
  # initialize test data
  # let!(:datacenters) { create_list(:datacenter, 10) }
  # let(:datacenter_id) { datacenters.first.id }

  # Test suite for GET /datacenters
  describe 'GET /datacenters' do
    # make HTTP get request before each example
    before { get '/datacenters' }

    it 'returns datacenters' do
      # Note `json` is a custom helper to parse JSON responses
      datacenters = JSON.parse(response.body)
      expect(datacenters).not_to be_empty
      expect(datacenters.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /datacenters/:id
  # describe 'GET /datacenters/:id' do
  #   before { get "/datacenters/#{datacenter_id}" }
  #
  #   context 'when the record exists' do
  #     it 'returns the datacenter' do
  #       expect(json).not_to be_empty
  #       expect(json['id']).to eq(datacenter_id)
  #     end
  #
  #     it 'returns status code 200' do
  #       expect(response).to have_http_status(200)
  #     end
  #   end
  #
  #   context 'when the record does not exist' do
  #     let(:datacenter_id) { 100 }
  #
  #     it 'returns status code 404' do
  #       expect(response).to have_http_status(404)
  #     end
  #
  #     it 'returns a not found message' do
  #       expect(response.body).to match(/Couldn't find datacenter/)
  #     end
  #   end
  # end

  # Test suite for POST /datacenters
  # describe 'POST /datacenters' do
  #   # valid payload
  #   let(:valid_attributes) { { name: '60 Hudson Street', symbol: 'Western.UB' } }
  #
  #   context 'when the request is valid' do
  #     before { post '/datacenters', params: valid_attributes }
  #
  #     it 'creates a datacenter' do
  #       expect(json['name']).to eq('60 Hudson Street')
  #     end
  #
  #     it 'returns status code 201' do
  #       expect(response).to have_http_status(201)
  #     end
  #   end
  #
  #   context 'when the request is invalid' do
  #     before { post '/datacenters', params: { symbol: 'Western.UB' } }
  #
  #     it 'returns status code 422' do
  #       expect(response).to have_http_status(422)
  #     end
  #
  #     it 'returns a validation failure message' do
  #       expect(response.body)
  #         .to match(/Validation failed: Created by can't be blank/)
  #     end
  #   end
  # end

  # # Test suite for PUT /datacenters/:id
  # describe 'PUT /datacenters/:id' do
  #   let(:valid_attributes) { { name: '60 Hudson Street' } }
  #
  #   context 'when the record exists' do
  #     before { put "/datacenters/#{datacenter_id}", params: valid_attributes }
  #
  #     it 'updates the record' do
  #       expect(response.body).to be_empty
  #     end
  #
  #     it 'returns status code 204' do
  #       expect(response).to have_http_status(204)
  #     end
  #   end
  # end
  #
  # # Test suite for DELETE /datacenters/:id
  # describe 'DELETE /datacenters/:id' do
  #   before { delete "/datacenters/#{datacenter_id}" }
  #
  #   it 'returns status code 204' do
  #     expect(response).to have_http_status(204)
  #   end
  # end
end
