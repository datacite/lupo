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

    it "returns data dumps with pagination" do
      get "/data_dumps?page[number]=1&page[size]=4"

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/data_dumps?page%5Bnumber%5D=2&page%5Bsize%5D=4")
      expect(json.dig("links", "prev")).to be_nil

      get next_link

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(10)
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/data_dumps?page%5Bnumber%5D=3&page%5Bsize%5D=4")
      prev_link_absolute = Addressable::URI.parse(json.dig("links", "prev"))
      prev_link = prev_link_absolute.path + "?" + prev_link_absolute.query
      expect(prev_link).to eq("/data_dumps?page%5Bnumber%5D=1&page%5Bsize%5D=4")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "next")).to be_nil
      prev_link_absolute = Addressable::URI.parse(json.dig("links", "prev"))
      prev_link = prev_link_absolute.path + "?" + prev_link_absolute.query
      expect(prev_link).to eq("/data_dumps?page%5Bnumber%5D=2&page%5Bsize%5D=4")
    end

    it "returns correct page links when results is exactly divisible by page size" do
      get "/data_dumps?page[number]=1&page[size]=5"

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "prev")).to be_nil
      next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
      next_link = next_link_absolute.path + "?" + next_link_absolute.query
      expect(next_link).to eq("/data_dumps?page%5Bnumber%5D=2&page%5Bsize%5D=5")

      get next_link, nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("links", "next")).to be_nil
      prev_link_absolute = Addressable::URI.parse(json.dig("links", "prev"))
      prev_link = prev_link_absolute.path + "?" + prev_link_absolute.query
      expect(prev_link).to eq("/data_dumps?page%5Bnumber%5D=1&page%5Bsize%5D=5")
    end

    it "returns a blank resultset when page is above max page" do
      get "/data_dumps?page[number]=3&page[size]=5"

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(0)
      expect(json.dig("meta", "totalPages")).to eq(2)
      expect(json.dig("meta", "page")).to eq(3)
      expect(json.dig("links", "next")).to be_nil
      prev_link_absolute = Addressable::URI.parse(json.dig("links", "prev"))
      prev_link = prev_link_absolute.path + "?" + prev_link_absolute.query
      expect(prev_link).to eq("/data_dumps?page%5Bnumber%5D=2&page%5Bsize%5D=5")
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
