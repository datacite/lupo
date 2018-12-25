class UrlJob < ActiveJob::Base
  queue_as :lupo

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  def perform(doi)
    logger = Logger.new(STDOUT)

    response = Maremma.head(doi.identifier, limit: 0)
    if response.headers.present?
      if doi.is_registered_or_findable? && doi.minted.blank?
        doi.update_attributes(url: response.headers["location"], minted: Time.zone.now)
      else
        doi.update_attributes(url: response.headers["location"])
      end

      logger.debug "Set URL #{response.headers["location"]} for DOI #{doi.doi}"
    end
  end
end
