class DoiImportByIdJob < ActiveJob::Base
  queue_as :lupo_import

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options={})
    Doi.import_by_id(options)
  end
end
