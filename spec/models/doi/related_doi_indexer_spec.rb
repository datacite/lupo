
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doi::Indexer::RelatedDoiIndexer, elasticsearch: false, skip_prefix_pool: true do
  describe "related_dois with different input" do
    let(:good_related_identifier) do
      {
        "relatedIdentifier": "10.1234/5678",
        "relatedIdentifierType": "DOI",
        "relationType": "IsPartOf",
      }.with_indifferent_access
    end

    it "handles nil input" do
      expect(described_class.new(nil).related_dois).to eq([])
    end

    it "handles empty_string input" do
      expect(described_class.new("").related_dois).to eq([])
    end

    it "handles a list with empty_string as input" do
      expect(described_class.new([""]).related_dois).to eq([])
    end


    it "handles array of hashes with all required keys" do
      expect(described_class.new([good_related_identifier]).related_dois).to eq(
        [good_related_identifier])
    end

    it "handles single hash with all required keys" do
      expect(described_class.new(good_related_identifier).related_dois).to eq(
        [good_related_identifier])
    end

    it "exclude DOIs with if a required key is missing" do
      expect(described_class.new(
        good_related_identifier.except("relatedIdentifier")
      ).related_dois).to eq([])
      expect(described_class.new(
        good_related_identifier.except("relatedIdentifierType")
      ).related_dois).to eq([])
      expect(described_class.new(
        good_related_identifier.except("relationType")
      ).related_dois).to eq([])
    end
  end

  describe "relation_type grouping" do
    let(:related_identifiers) do
      [
        {
          "relatedIdentifier": "10.1234/5678",
          "relatedIdentifierType": "DOI",
          "relationType": "IsPartOf",
          "resourceTypeGeneral": "Dataset",
        }.with_indifferent_access,
        {
          "relatedIdentifier": "10.1234/9999",
          "relatedIdentifierType": "DOI",
          "relationType": "HasVersion",
          "resourceTypeGeneral": "Text",
        }.with_indifferent_access,
        {
          "relatedIdentifier": "10.1234/9999",
          "relatedIdentifierType": "DOI",
          "relationType": "References",
          "resourceTypeGeneral": "Text",
        }.with_indifferent_access
      ]
    end

    it "can accept an array of valid identifiers" do
      expect(described_class.new(related_identifiers).related_dois).to eq(related_identifiers)
    end

    it "groups related_dois by relatedIdentifier" do
      expect(described_class.new(related_identifiers).relation_types_gouped_by_id).to eq(
        {
          "10.1234/5678" => ["is_part_of"],
          "10.1234/9999" => ["has_version", "references"],
        }
      )
    end

    it "groups related_dois by relatedIdentifier" do
      expect(described_class.new(related_identifiers).related_grouped_by_id).to eq(
        {
          "10.1234/5678" => [
            {
              "relatedIdentifier" => "10.1234/5678",
              "relatedIdentifierType" => "DOI",
              "relationType" => "IsPartOf",
              "resourceTypeGeneral" => "Dataset",
            }
          ],
          "10.1234/9999" => [
            {
              "relatedIdentifier" => "10.1234/9999",
              "relatedIdentifierType" => "DOI",
              "relationType" => "HasVersion",
              "resourceTypeGeneral" => "Text",
            },
            {
              "relatedIdentifier" => "10.1234/9999",
              "relatedIdentifierType" => "DOI",
              "relationType" => "References",
              "resourceTypeGeneral" => "Text",
            }
          ],
        }
      )
    end
  end
end
