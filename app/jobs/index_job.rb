class IndexJob < ActiveJob::Base
  queue_as :lupo

  rescue_from ActiveJob::DeserializationError do |error|
    logger = Logger.new(STDOUT)
    logger.error error.message
  end

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end