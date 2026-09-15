class Enrichment < ApplicationRecord
  before_validation :set_defaults
  before_validation :normalize_source_id

  validates :uuid, presence: true, uniqueness: true
  validates :source_id, presence: true
  validate :validate_json_schema

  belongs_to :doi_record,
    class_name: "Doi",
    foreign_key: :doi, # enrichments.doi
    primary_key: :doi, # dois.doi
    optional: false

  has_one :client, through: :doi_record

  after_destroy_commit :sync_doi_enrichment_index

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
    def sync_doi_enrichment_index
      datacite_doi = DataciteDoi.find_by(doi: doi, type: "DataciteDoi")
      return if datacite_doi.blank?
      return if Enrichment.exists?(doi: doi)

      # Reindex so the DataciteDoi document's computed has_enrichments is false.
      datacite_doi.touch
      EnrichedDoiDeleteJob.enqueue_for_datacite_doi(datacite_doi)
    end

    def set_defaults
      self.uuid = SecureRandom.uuid if uuid.blank?
    end

    def normalize_source_id
      self.source_id = source_id&.strip&.upcase
    end

    def validate_json_schema
      doc = to_enrichment_hash
      error_list = self.class.enrichment_schemer.validate(doc).to_a

      return if error_list.empty?

      errors.add(:base, "Validation failed: #{error_list.map { |e| e['message'] || e.inspect }.join('; ')}")
    end

    def to_enrichment_hash
      {
        "doi" => doi,
        "sourceId" => source_id,
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
