class IndexJob < ActiveJob::Base
  queue_as :lupo

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = LogStashLogger.new(type: :stdout) 
    logger.error error.message
  end

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end