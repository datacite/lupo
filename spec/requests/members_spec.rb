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
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/members/#{provider.uid}"

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "title")).to eq(provider.name)
          expect_legacy_sunset_headers
        end
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/members/xxx"

          expect(last_response.status).to eq(404)
          expect(json["errors"].first).to eq(
            "status" => "404",
            "title" => "The resource you are looking for doesn't exist.",
          )
          expect_legacy_sunset_headers
        end
      end
    end
  end

  describe "after legacy sunset date" do
    around do |example|
      travel_to(Time.utc(2026, 7, 1, 0, 0, 0)) { example.run }
    end

    it "returns 410 for GET /members/:id" do
      get "/members/#{provider.uid}"

      expect(last_response.status).to eq(410)
      expect(json["errors"].first).to include(
        "status" => "410",
        "title" => "This endpoint has been deprecated and is no longer available.",
        "detail" => "Use GET /providers instead of GET /members/#{provider.uid}.",
      )
      expect(last_response.headers["Sunset"]).to be_nil
      expect(last_response.headers["Link"]).to include('rel="sunset"')
    end

    it "does not affect GET /providers/:id" do
      get "/providers/#{provider.uid}"

      expect(last_response.status).to eq(200)
      expect_no_legacy_sunset_header
    end
  end
end
