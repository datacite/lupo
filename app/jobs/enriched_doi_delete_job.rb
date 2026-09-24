# frozen_string_literal: true

class EnrichedDoiDeleteJob < ApplicationJob
  queue_as :enriched_doi_index_job

  def self.enqueue_for_datacite_doi(source_doi)
    return unless source_doi.instance_of?(DataciteDoi)
    return if source_doi.has_enrichments

    perform_later(source_doi.doi, target_active_index: true)

    if source_doi.index_sync_enabled?
      perform_later(source_doi.doi, target_active_index: false)
    end
  end

  rescue_from ActiveJob::DeserializationError,
              SocketError,
              Elastic::Transport::Transport::Errors::BadRequest,
              Elastic::Transport::Transport::Error do |error|
    Rails.logger.error error.message
  end

  def perform(doi, target_active_index: true)
    log_prefix = "[EnrichedDoiDeleteJob]"
    target_index = target_active_index ? EnrichedDoi.active_index : EnrichedDoi.inactive_index
    source_doi = Doi.includes(:enrichments).find_by(doi: doi, agency: "datacite")

    if source_doi.blank?
      Rails.logger.info("#{log_prefix}: DOI not found: #{doi}")
      return
    end

    return if source_doi.has_enrichments

    enriched_doi = EnrichedDoi.instantiate(source_doi.attributes)
    enriched_doi.__elasticsearch__.delete_document(index: target_index)
    Rails.logger.info("#{log_prefix}: Deleted EnrichedDoi #{doi} from #{target_index}")
  rescue Elastic::Transport::Transport::Errors::NotFound => e
    Rails.logger.warn("#{log_prefix}: Document not found in #{target_index}: #{e.message}")
  end
end
