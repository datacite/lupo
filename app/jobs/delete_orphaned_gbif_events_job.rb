# frozen_string_literal: true

class DeleteOrphanedGbifEventsJob < ApplicationJob
  queue_as :lupo_background

  def perform(env, options)
    label = "DeleteOrphanedGbifEventsJob_#{Time.now.utc.strftime("%d%m%Y%H%M%S")}"

    Rails.logger.info("#{label}: index_name: #{env}")
    Rails.logger.info("#{label}: query: #{query}")

    # response = Event.delete_by_query(index: env, query: options[:query])

    # Rails.logger.info(response.to_json)
  rescue => err
    Rails.logger.info("#{label}: #{err.message}")
  end
end
