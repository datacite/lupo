require 'rails_helper'

describe 'Members', type: :request do
  let!(:providers)  { create_list(:provider, 10) }
  let(:provider)  { create(:provider) }

  # describe 'GET /members', elasticsearch: true do
  #   before do
  #     sleep 1
  #     get '/members'
  #   end

  #   it 'returns members' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(10)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  # describe 'GET /members query', elasticsearch: true do
  #   before do
  #     sleep 1
  #     get "/members?query=my"
  #   end

  #   it 'returns members' do
  #     expect(json).not_to be_empty
  #     expect(json['data'].size).to eq(10)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  describe 'GET /members/:id' do
    before { get "/members/#{provider.uid}" }

    context 'when the record exists' do
      it 'returns the member' do
        expect(json.dig('data', 'attributes', 'title')).to eq(provider.name)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      before { get "/members/xxx" }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(json["errors"].first).to eq("status"=>"404", "title"=>"The resource you are looking for doesn't exist.")
      end
    end
  end
end
