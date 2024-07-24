# frozen_string_literal: true

class DeleteGbifEventsJob < ApplicationJob
  queue_as :lupo_background

  def perform(id, options = {})
    event = Event.find_by(uuid: id)

    event.destroy! if event.present?
  rescue => err
    Rails.logger.info("#{options[:label]}: event delete error: #{err.message}")
  end
end
