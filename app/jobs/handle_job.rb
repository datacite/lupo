class HandleJob < ActiveJob::Base
  queue_as :lupo

  def perform(doi, options={})
    doi.register_url(options)
  end
end
