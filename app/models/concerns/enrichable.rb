# frozen_string_literal: true

module Enrichable
  extend ActiveSupport::Concern

  def apply_enrichment(enrichment)
    action = enrichment["action"]

    field = enrichment_field(enrichment["field"])

    raise ArgumentError, "Invalid enrichment field #{enrichment["field"]}" if field.nil?

    case action
    when "insert"
      self[field] ||= []
      self[field] << enrichment["enriched_value"]
    when "update"
      self[field] = enrichment["enriched_value"]
    when "update_child"
      self[field].each_with_index do |item, index|
        if item == enrichment["original_value"]
          self[field][index] = enrichment["enriched_value"]
        end
      end
    when "delete_child"
      self[field] ||= []
      self[field].each_with_index do |item, index|
        if item == enrichment["original_value"]
          self[field].delete_at(index)
          break
        end
      end
    end
  end

  def enrichment_field(field)
    field_mapping = {
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
    }

    field_mapping.fetch(field, nil)
  end
end
