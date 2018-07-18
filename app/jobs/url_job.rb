class UrlJob < ActiveJob::Base
  queue_as :lupo

  retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  def perform(doi)
    Rails.logger.debug "Set URL for #{doi.doi}"
    doi.send(:set_url)
  end
end
