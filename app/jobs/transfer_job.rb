# frozen_string_literal: true

class TransferJob < ApplicationJob
  queue_as :lupo_transfer

  # retry_on ActiveRecord::RecordNotFound, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(doi_id, options = {})
    doi = Doi.where(doi: doi_id).first

    # Success starts as true because update_attributes only returns false on error.

    if doi.present? && options[:client_target_id].present?
      success = true
      success = doi.update(datacentre: options[:client_target_id])

      __elasticsearch__.index_document if success

      Rails.logger.info "[Transfer] Transferred DOI #{doi.doi}."
    elsif doi.present?
      Rails.logger.error "[Transfer] Error transferring DOI " + doi_id +
        ": no target client"
    else
      Rails.logger.error "[Transfer] Error transferring DOI " + doi_id +
        ": not found"
    end
  end
end
