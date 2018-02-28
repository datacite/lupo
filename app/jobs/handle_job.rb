class HandleJob < ActiveJob::Base
  queue_as :lupo

  def perform(doi, options={})
    Rails.logger.debug "Update handle record for #{doi.doi}"
    doi.send(:set_url)
  end
end
