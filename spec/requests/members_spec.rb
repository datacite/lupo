# frozen_string_literal: true

require "rails_helper"

describe MembersController, type: :request do
  let!(:providers) { create_list(:provider, 10) }
  let(:provider) { create(:provider) }

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

  describe "GET /members/:id" do
    context "when the record exists" do
      it "returns the member" do
        get "/members/#{provider.uid}"

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "title")).to eq(provider.name)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/members/xxx"

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end
end
