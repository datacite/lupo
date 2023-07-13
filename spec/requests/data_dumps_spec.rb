# frozen_string_literal: true

require "rails_helper"

describe DataDumpsController, type: :request, elasticsearch: true do
  let(:data_dump) { create(:data_dump, uid: "test_dump") }

  describe "GET /data_dumps", elasticsearch: true do
    let!(:data_dumps) { create_list(:data_dump, 10) }

    before do
      DataDump.import
      sleep 1
    end

    it "returns data dumps" do
      get "/data_dumps"

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(10)
      expect(json.dig("meta", "total")).to eq(10)
    end
  end

  describe "GET /data_dumps/:id" do
    context "when the record exists" do
      it "returns the record" do
        get "/data_dumps/#{data_dump.uid}"

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "description")).to eq("Test Metadata Data Dump Factory creation")
        expect(json.dig("data", "attributes", "start_date")).to eq(data_dump.start_date)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/data_dumps/invalid_id"

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq("status" => "404", "title" => "The resource you are looking for doesn't exist.")
      end
    end
  end
end
