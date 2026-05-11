# frozen_string_literal: true

class EnrichedDoiIndexJob < ApplicationJob
  queue_as :enriched_doi_index_job

  rescue_from ActiveJob::DeserializationError,
              SocketError,
              Elasticsearch::Transport::Transport::Errors::BadRequest,
              Elasticsearch::Transport::Transport::Error do |error|
    Rails.logger.error error.message
  end

  def perform(doi)
    log_prefix = "[EnrichedDoiIndexJob]"
    source_doi = Doi.includes(:enrichments).find_by(doi: doi, agency: "datacite")

    if source_doi.blank?
      Rails.logger.info("#{log_prefix}: DOI not found: #{doi}")
      return
    end

    source_doi.only_validate = true
    source_doi.regenerate = true
    source_doi.skip_client_domains_validation = true
    source_doi.skip_schema_version_validation = false
    source_doi.schema_version = "http://datacite.org/schema/kernel-4"

    source_doi.enrichments.each do |enrichment|
      begin
        source_doi.apply_enrichment(enrichment)
      rescue => e
        Rails.logger.error("#{log_prefix}: Failed to apply enrichment for DOI #{source_doi.doi}: #{e.message}")
      end
    end

    if source_doi.invalid?
      Rails.logger.error("#{log_prefix}: DOI invalid after enrichment: #{source_doi.doi}")
      return
    end

    enriched_doi = EnrichedDoi.new(source_doi.attributes)
    enriched_doi.id = source_doi.id
    enriched_doi.created_at = source_doi.created_at
    enriched_doi.updated_at = source_doi.updated_at

    response = enriched_doi.__elasticsearch__.index_document
    Rails.logger.error("[Elasticsearch] Error #{response.inspect}") unless %w[created updated].include?(response["result"])
  end
end
