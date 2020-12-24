# frozen_string_literal: true

class IndexBackgroundJob < ApplicationJob
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError,
              Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(obj)
    response = obj.__elasticsearch__.index_document
    # Rails.logger.error "[Elasticsearch] Error indexing id #{response["_id"]} in index #{response["_index"]}" if response["result"] != "created"
    Rails.logger.error "[Elasticsearch] Error #{response.inspect}" unless %w(created updated).include?(response["result"])
  end
end
