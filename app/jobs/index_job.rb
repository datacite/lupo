# frozen_string_literal: true

class IndexJob < ApplicationJob
  queue_as :lupo

  rescue_from ActiveJob::DeserializationError,
              Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(obj)
    obj.__elasticsearch__.index_document
  end
end
