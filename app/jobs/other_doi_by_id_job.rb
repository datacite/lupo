# frozen_string_literal: true

class OtherDoiByIdJob < ApplicationJob
  queue_as :events_other_doi_by_id_job

  # retry_on ActiveRecord::Deadlocked, wait: 10.seconds, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 10.minutes, attempts: 3

  # discard_on ActiveJob::DeserializationError

  rescue_from ActiveJob::DeserializationError,
              Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    Rails.logger.error error.message
  end

  def perform(id, options = {})
    # Event.import_doi(id, options)
    Rails.logger.info("OtherDoiByIdJob id: #{id}")
  end
end
