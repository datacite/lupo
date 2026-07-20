# frozen_string_literal: true

class EnrichedDoiIndexJob < ApplicationJob
  queue_as :enriched_doi_index_job

  def self.enqueue_for_datacite_doi(source_doi, target_active_index: true)
    return unless source_doi.instance_of?(DataciteDoi)
    return unless source_doi.has_enrichments

    perform_later(source_doi.doi, target_active_index: target_active_index)
  end

  rescue_from ActiveJob::DeserializationError,
              SocketError,
              Elasticsearch::Transport::Transport::Errors::BadRequest,
              Elasticsearch::Transport::Transport::Error do |error|
    Rails.logger.error error.message
  end

  def perform(doi, target_active_index: true)
    log_prefix = "[EnrichedDoiIndexJob]"
    target_index = target_active_index ? EnrichedDoi.active_index : EnrichedDoi.inactive_index
    source_doi = Doi.includes(:enrichments).find_by(doi: doi, agency: "datacite")

    if source_doi.blank?
      Rails.logger.info("#{log_prefix}: DOI not found: #{doi}")
      return
    end

    if source_doi.enrichments.blank?
      begin
        EnrichedDoi.__elasticsearch__.client.delete(
          index: target_index,
          id: source_doi.id,
        )
      rescue => e
        Rails.logger.error("#{log_prefix}: Failed to delete enriched DOI #{source_doi.doi}: #{e.message}")
      end

      return
    end

    source_doi.only_validate = true
    source_doi.regenerate = true
    source_doi.skip_client_domains_validation = true
    source_doi.skip_schema_version_validation = false
    source_doi.schema_version = "http://datacite.org/schema/kernel-4"

    source_doi.enrichments.each do |enrichment|
      source_doi.apply_enrichment(enrichment)
    rescue => e
      Rails.logger.error("#{log_prefix}: Failed to apply enrichment for DOI #{source_doi.doi}: #{e.message}")
    end

    if source_doi.invalid?
      Rails.logger.error("#{log_prefix}: DOI invalid after enrichment: #{source_doi.doi}")
      return
    end

    enriched_doi = EnrichedDoi.new(source_doi.attributes)
    enriched_doi.id = source_doi.id
    enriched_doi.created_at = source_doi.created_at
    enriched_doi.updated_at = source_doi.updated_at

    response = enriched_doi.__elasticsearch__.index_document(index: target_index)
    Rails.logger.error("[Elasticsearch] Error #{response.inspect}") unless %w[created updated].include?(response["result"])
  end
end
