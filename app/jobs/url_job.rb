class UrlJob < ActiveJob::Base
  queue_as :lupo

  def perform(doi)
    Rails.logger.debug "Set URL for #{doi.doi}"
    doi.send(:set_url)
  end
end
