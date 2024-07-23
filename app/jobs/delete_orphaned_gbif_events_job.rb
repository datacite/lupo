# frozen_string_literal: true

class DeleteOrphanedGbifEventsJob < ApplicationJob
  queue_as :lupo_background

  def perform(env, query)
    label = "DeleteOrphanedGbifEventsJob_#{Time.now.utc.strftime("%d%m%Y%H%M%S")}"

    Rails.logger.info("#{label}: index_name: #{env}")

    # response = Event.delete_by_query(index: env, query: query)

    # Rails.logger.info(response.to_json)
  rescue => err
    Rails.logger.info("#{options[:label]}: event delete error: #{err.message}")
  end
end
