class HandleJob < ActiveJob::Base
  queue_as :lupo

  retry_on ActiveRecord::RecordNotFound, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  discard_on ActiveJob::DeserializationError

  def perform(doi)
    Rails.logger.debug "Update Handle record for #{doi.doi}"
    doi.register_url
  end
end
