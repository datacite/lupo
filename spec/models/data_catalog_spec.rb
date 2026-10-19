# frozen_string_literal: true

require "rails_helper"

describe DataCatalog, type: :model do
  describe "find_by_id" do
    it "does not call the retired re3data endpoint" do
      result = described_class.find_by_id("https://doi.org/10.17616/r3qp53")

      expect(result[:data]).to eq([])
      expect(result[:errors]).to be_nil
      expect(WebMock).not_to have_requested(:get, %r{api\.datacite\.org/re3data})
    end
  end

  describe "query" do
    it "returns an empty page" do
      result = described_class.query("climate", pid: true, offset: 2)

      expect(result[:data]).to eq([])
      expect(result.dig(:meta, "total")).to eq(0)
      expect(result[:errors]).to be_nil
    end
  end

  describe "fetch_and_cache_all" do
    it "returns no repositories" do
      expect(described_class.fetch_and_cache_all(pages: 1)).to eq([])
    end
  end
end
