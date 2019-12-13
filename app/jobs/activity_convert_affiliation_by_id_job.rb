class ActivityConvertAffiliationByIdJob < ActiveJob::Base
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = LogStashLogger.new(type: :stdout)
    logger.error error.message
  end

  def perform(options={})
    Activity.convert_affiliation_by_id(options)
  end
end
