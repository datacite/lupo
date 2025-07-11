
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::GraphqlQuery::Builder, elasticsearch: false, skip_prefix_pool: true do
  let(:query) { "" }
  let(:options) { {} }
  describe "page size" do
    let(:builder) { described_class.new(query, options) }

    it "is DEFAULT_PAGE_SIZE with no options" do
      expect(builder.size).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    context "when set in options" do
      let(:test_size) { 10 }
      let(:options) { { page: { size: test_size } } }
      it "will override DEFAULT_PAGE_SIZE" do
        expect(builder.size).to eq(test_size)
      end
    end
  end

  describe "cursor" do
    let(:builder) { described_class.new(query, options) }

    it "is DEFAULT_CURSOR with no options" do
      expect(builder.cursor).to eq(described_class::DEFAULT_CURSOR)
    end

    context "when set in options" do
      let(:test_cursor) { [1, "2"] }
      let(:options) { { page: { cursor: test_cursor } } }
      it "will override DEFAULT_CURSOR" do
        expect(builder.cursor).to eq(test_cursor)
      end
    end
  end

  describe "cleaned query" do
    it "is an empty string if not set" do
      expect(described_class.new("", {}).clean_query).to eq("")
      expect(described_class.new(nil, {}).clean_query).to eq("")
    end


    it "replaces several camelcase words with underscores" do
      described_class::QUERY_SUBSTITUTIONS.each do |key, value|
        expect(described_class.new(key, {}).clean_query).to eq(value)
      end
    end

    it "escapses foward slashes" do
      expect(described_class.new("foo/bar", {}).clean_query).to eq("foo\\/bar")
    end
  end

  describe "sorting" do
    let(:builder) { described_class.new(query, options) }

    context "with no sort options" do
      it "uses default sort" do
        expect(builder.sort).to eq(described_class::DEFAULT_SORT)
      end
    end

    context "with sort options" do
      let(:options) { { sort: "relevance" } }
      it "ignores any sort options and returns the default" do
        expect(builder.sort).to eq(described_class::DEFAULT_SORT)
      end
    end
  end
end
