# frozen_string_literal: true

class IndexBackgroundJob < ApplicationJob
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError,
              SocketError,
              Elasticsearch::Transport::Transport::Errors::BadRequest,
              Elasticsearch::Transport::Transport::Error do |error|
    Rails.logger.error error.message
  end
  def perform(obj)
    response = obj.__elasticsearch__.index_document
    Rails.logger.error "[Elasticsearch] Error #{response.inspect}" unless %w(created updated).include?(response["result"])
  end
end
