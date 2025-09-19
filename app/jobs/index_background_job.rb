# frozen_string_literal: true

class IndexBackgroundJob < ApplicationJob
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError,
              SocketError,
              Elasticsearch::Transport::Transport::Errors::BadRequest,
              Elasticsearch::Transport::Transport::Error do |error|
    Rails.logger.error error.message
  end

  def index_sync_enabled?(obj)
    if Rails.env.test?
      return false
    end
    obj.respond_to?(:index_sync_enabled?) && obj.index_sync_enabled?
  end

  def perform(obj)
    response = obj.__elasticsearch__.index_document
    Rails.logger.error "[Elasticsearch] Error #{response.inspect}" unless %w(created updated).include?(response["result"])
    if index_sync_enabled?(obj)
      response2 = obj.__elasticsearch__.index_document(index: obj.inactive_index)
      Rails.logger.error "[Elasticsearch] Error #{response2.inspect}" unless %w(created updated).include?(response2["result"])
    end
  end
end
