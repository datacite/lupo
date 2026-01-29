class Enrichment < ApplicationRecord
  validate :validate_json_schema

  private

  def validate_json_schema
    doc = to_enrichment_hash
    error_list = self.class.enrichment_schemer.validate(doc).to_a

    return if error_list.empty?

    errors.add(:base, "Validation failed: #{error_list.map { |e| e['message'] || e.inspect }.join('; ')}")
  end

  def to_enrichment_hash
    {
      "doi" => doi,
      "contributors" => contributors,
      "resources" => resources,
      "field" => field,
      "action" => action,
      "originalValue" => original_value,
      "enrichedValue" => enriched_value
    }.compact
  end

  def self.enrichment_schemer
    @enrichment_schemer ||= begin
      schema_path = Rails.root.join("app/models/schemas/enrichment/enrichment.json")
      schema = JSON.parse(File.read(schema_path))
      JSONSchemer.schema(schema)
    end
  end
end
