class ActivityImportByIdJob < ActiveJob::Base
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = LogStashLogger.new(type: :stdout)
    logger.error error.message
  end

  def perform(options={})
    Activity.import_by_id(options)
  end
end
