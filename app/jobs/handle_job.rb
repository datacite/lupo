class HandleJob < ActiveJob::Base
  queue_as :lupo

  def perform(doi, options={})
    Rails.logger.debug "Update Handle record for #{doi.doi}"
    doi.register_url(options)
  end
end
