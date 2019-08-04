class DoiConvertContainerByIdJob < ActiveJob::Base
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = Logger.new(STDOUT)
    logger.error error.message
  end

  def perform(options={})
    Doi.convert_container_by_id(options)
  end
end
