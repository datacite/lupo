class UrlJob < ActiveJob::Base
  queue_as :default

  rescue_from ActiveJob::DeserializationError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :default
  end

  def perform(doi)
    Rails.logger.debug "Set URL for #{doi.doi}"
    doi.send(:set_url)
  end
end
