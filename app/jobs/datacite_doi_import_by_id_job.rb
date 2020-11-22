# frozen_string_literal: true

class DataciteDoiImportByIdJob < ApplicationJob
  queue_as :lupo_import

  rescue_from ActiveJob::DeserializationError,
              Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options = {})
    DataciteDoi.import_by_id(options)
  end
end
