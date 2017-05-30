require 'rails_helper'

RSpec.describe 'Datacentres', type: :request, vcr: true  do
  # initialize test data
  let!(:datacentres)  { create_list(:datacentre, 10) }
  let(:datacentre_id) { datacentres.first.id }

  # Test suite for GET /datacentres
  describe 'GET /datacentres' do
    # make HTTP get request before each example
    before { get '/datacentres' }

    it 'returns datacentres' do
      expect(json).not_to be_empty
      expect(json['data'].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /datacentres/:id
  describe 'GET /datacentres/:id' do
    before { get "/datacentres/#{datacentre_id}" }

    context 'when the record exists' do
      it 'returns the datacentre' do
        expect(json).not_to be_empty
        expect(json['data']['id']).to eq(datacentre_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:datacentre_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Record not found/)
      end
    end
  end

  # Test suite for POST /datacentres
  describe 'POST /datacentres' do
    # valid payload
    let(:valid_attributes) { { name: '60HudsonStreet', symbol: 'Western.UB'} }

    context 'when the request is valid' do
      before { post '/datacentres', params: valid_attributes, headers: {'HTTP_ACCESS'=>'application/vnd.api+json', 'CONTENT_TYPE'=>'application/vnd.api+json'} }

      it 'creates a datacentre' do
        puts json
        expect(json['name']).to eq('60HudsonStreet')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/datacentres', params: { symbfol: 'Western.UB' } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      # it 'returns a validation failure message' do
      #   expect(response.body).to match(/Validation failed: Created by can't be blank/)
      # end
    end
  end

  # # Test suite for PUT /datacentres/:id
  # describe 'PUT /datacentres/:id' do
  #   let(:valid_attributes) { { name: '60 Hudson Street' } }
  #
  #   context 'when the record exists' do
  #     before { put "/datacentres/#{datacentre_id}", params: valid_attributes }
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

  # Test suite for DELETE /datacentres/:id
  describe 'DELETE /datacentres/:id' do
    before { delete "/datacentres/#{datacentre_id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
