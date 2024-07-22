# frozen_string_literal: true

class DeleteOrphanedGbifEventsJob < ApplicationJob
  queue_as :lupo_background

  def perform(env, query)
    Rails.logger.info("index: #{env}")

    # response = Event.delete_by_query(index: env, query: query)

    # Rails.logger.info(response.to_json)
  rescue => err
    Rails.logger.info("#{options[:label]}: event delete error: #{err.message}")
  end
end
