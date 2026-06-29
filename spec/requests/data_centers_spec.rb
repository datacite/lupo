# frozen_string_literal: true

require "rails_helper"

describe DataCentersController, type: :request do
  let(:provider) { create(:provider) }
  let!(:client) { create(:client, provider: provider) }

  describe "GET /data-centers/:id" do
    context "when the record exists" do
      it "returns the data center" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/data-centers/#{client.uid}"

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "title")).to eq(client.name)
          expect_legacy_sunset_headers
        end
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/data-centers/xxx"

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

    it "returns 410 for GET /data-centers/:id" do
      get "/data-centers/#{client.uid}"

      expect(last_response.status).to eq(410)
      expect(json["errors"].first).to include(
        "status" => "410",
        "title" => "This endpoint has been deprecated and is no longer available.",
        "detail" => "Use GET /clients instead of GET /data-centers/#{client.uid}.",
      )
      expect(last_response.headers["Sunset"]).to be_nil
      expect(last_response.headers["Link"]).to include('rel="sunset"')
    end

    it "does not affect GET /clients/:id" do
      get "/clients/#{client.uid}"

      expect(last_response.status).to eq(200)
      expect_no_legacy_sunset_header
    end
  end
end
