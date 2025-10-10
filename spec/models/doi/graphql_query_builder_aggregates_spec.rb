# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::GraphqlQuery::Builder, elasticsearch: false, skip_prefix_pool: true do
  let(:query) { "" }
  let(:options) { {} }

  describe "aggregations" do
    it "by default all aggregations are enabled" do
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq(described_class.all_aggregations)
    end

    it "has keys for all aggregates" do
      expected_keys = %i[
        affiliations
        authors
        citation_count
        client_types
        clients
        content_url_count
        creators_and_contributors
        download_count
        fields_of_science
        fields_of_science_combined
        fields_of_science_repository
        funders
        languages
        licenses
        open_licenses
        pid_entities
        published
        registration_agencies
        resource_types
        view_count
      ]

      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end
  end

  describe "include aggregations" do
    it "includes all aggregations by default" do
      expected_keys = described_class.all_aggregation_keys
      options = {}
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "includes all aggregations when :all symbol provided" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: :all }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "includes all aggregations when 'all' string provided" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: "all" }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end

    it "returns empty hash when :none provided" do
      options = { include_aggregations: :none }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "returns empty hash when 'none' string provided" do
      options = { include_aggregations: "none" }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "returns empty hash when empty array provided" do
      options = { include_aggregations: [] }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "returns empty hash when empty string provided" do
      options = { include_aggregations: "" }
      builder = described_class.new(query, options)
      expect(builder.aggregations).to eq({})
    end

    it "includes only specified aggregations when array of symbols provided" do
      options = { include_aggregations: [:clients, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "ignores invalid aggregation keys" do
      options = { include_aggregations: [:clients, :invalid_key, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "includes only specified aggregations when array of strings provided" do
      options = { include_aggregations: ["clients", "languages"] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "includes only specified aggregations when comma separated string provided" do
      options = { include_aggregations: "clients,languages" }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "includes only specified aggregations when comma separated string provided with spaces" do
      options = { include_aggregations: "clients, languages" }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array([:clients, :languages])
    end

    it "includes all aggregations when :all is included in array" do
      expected_keys = described_class.all_aggregation_keys
      options = { include_aggregations: [:clients, :all, :languages] }
      builder = described_class.new(query, options)
      expect(builder.aggregations.keys).to match_array(expected_keys)
    end
  end
end
