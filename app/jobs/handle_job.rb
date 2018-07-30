class HandleJob < ActiveJob::Base
  queue_as :lupo

  # retry_on ActiveRecord::RecordNotFound, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(doi_id)
    Rails.logger.debug "Update Handle record for #{doi_id}"
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      doi.register_url
    else
      Rails.logger.info "[Handle] Error updating URL for DOI " + doi_id + ": not found"
    end
  end
end
