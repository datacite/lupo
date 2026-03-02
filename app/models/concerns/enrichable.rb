# frozen_string_literal: true

module Enrichable
  extend ActiveSupport::Concern

  FIELD_MAPPING = {
    "alternateIdentifiers" => "alternate_identifiers",
    "creators" => "creators",
    "titles" => "titles",
    "publisher" => "publisher",
    "publicationYear" => "publication_year",
    "subjects" => "subjects",
    "contributors" => "contributors",
    "dates" => "dates",
    "language" => "language",
    "types" => "types",
    "relatedIdentifiers" => "related_identifiers",
    "relatedItems" => "related_items",
    "sizes" => "sizes",
    "formats" => "formats",
    "version" => "version",
    "rightsList" => "rights_list",
    "descriptions" => "descriptions",
    "geoLocations" => "geo_locations",
    "fundingReferences" => "funding_references"
  }.freeze

  def apply_enrichment(enrichment)
    action = enrichment.action
    field = enrichment_field(enrichment.field)

    case action
    when "insert"
      self[field] ||= []
      self[field] << enrichment.enriched_value
    when "update"
      if self[field] == enrichment.original_value
        self[field] = enrichment.enriched_value
      else
        raise ArgumentError, "Original value does not match current value for update action"
      end
    when "updateChild"
      success = false
      self[field] ||= []
      self[field].each_with_index do |item, index|
        if item == enrichment.original_value
          self[field][index] = enrichment.enriched_value
          success = true
          break
        end
      end

      raise ArgumentError, "Original value not found for updateChild action" unless success
    when "deleteChild"
      success = false
      self[field] ||= []
      self[field].each_with_index do |item, index|
        if item == enrichment.original_value
          self[field].delete_at(index)
          success = true
        end
      end

      raise ArgumentError, "Original value not found for deleteChild action" unless success
    end
  end

  def enrichment_field(field)
    FIELD_MAPPING.fetch(field, nil)
  end
end
