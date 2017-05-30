require 'rails_helper'

RSpec.describe "Allocators", type: :request do
  # initialize test data
  let!(:allocators)  { create_list(:allocator, 10) }
  let(:allocator_id) { allocators.first.id }

  # Test suite for GET /allocators
  describe 'GET /allocators' do
    # make HTTP get request before each example
    before { get '/allocators' }

    it 'returns allocators' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /allocators/:id
  describe 'GET /allocators/:id' do
    before { get "/allocators/#{allocator_id}" }

    context 'when the record exists' do
      it 'returns the allocator' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(allocator_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:allocator_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /allocators
  describe 'POST /allocators' do
    # valid payload
    let(:valid_attributes) { { name: '60HudsonStreet', symbol: 'Western.UB'} }

    context 'when the request is valid' do
      before { post '/allocators', params: valid_attributes, headers: {'HTTP_ACCESS'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json'} }

      it 'creates a allocator' do
        puts json
        expect(json['name']).to eq('60HudsonStreet')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/allocators', params: { symbfol: 'Western.UB' } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      # it 'returns a validation failure message' do
      #   expect(response.body).to match(/Validation failed: Created by can't be blank/)
      # end
    end
  end

  # # Test suite for PUT /allocators/:id
  # describe 'PUT /allocators/:id' do
  #   let(:valid_attributes) { { name: '60 Hudson Street' } }
  #
  #   context 'when the record exists' do
  #     before { put "/allocators/#{allocator_id}", params: valid_attributes }
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

  # Test suite for DELETE /allocators/:id
  describe 'DELETE /allocators/:id' do
    before { delete "/allocators/#{allocator_id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
