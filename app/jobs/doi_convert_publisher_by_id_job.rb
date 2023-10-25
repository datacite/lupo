# frozen_string_literal: true

class DoiConvertPublisherByIdJob < ApplicationJob
  queue_as :lupo_background

  rescue_from ActiveJob::DeserializationError,
              Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(options = {})
    Doi.convert_publisher_by_id(options)
  end
end
