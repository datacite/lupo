class OtherDoiImportByIdJob < ApplicationJob
  queue_as :lupo_import_other_doi

  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options = {})
    OtherDoi.import_by_id(options)
  end
end
