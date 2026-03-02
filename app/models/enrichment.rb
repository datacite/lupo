class Enrichment < ApplicationRecord
  validate :validate_json_schema

  belongs_to :doi_record,
    class_name: "Doi",
    foreign_key: :doi, # enrichments.doi
    primary_key: :doi, # dois.doi
    optional: false

  has_one :client, through: :doi_record

  scope :by_doi, ->(doi) { where(doi: doi) }

  scope :by_client, ->(client_id) { joins(doi_record: :client).where(datacentre: { symbol: client_id }) }

  scope :by_cursor, ->(updated_at, id) {
    where("(enrichments.updated_at < ?) OR (enrichments.updated_at = ? AND enrichments.id < ?)",
      updated_at,
      updated_at,
      id)
  }

  scope :order_by_cursor, -> { order(updated_at: :desc, id: :desc) }

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
