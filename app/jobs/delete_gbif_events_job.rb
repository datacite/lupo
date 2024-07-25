# frozen_string_literal: true

class DeleteGbifEventsJob < ApplicationJob
  queue_as :lupo_background

  def perform(ids, options = {})
    label = options[:label]
    index = ENV["INDEX"]

    if index.blank?
      Rails.logger.error("#{label}: ENV['INDEX'] must be provided")
      return
    end

    # delete event records from mysql
    result = Events.where(id: ids).delete_all
    Rails.logger.info("#{label}: #{result} event records deleted")

    # delete event documents from elasticsearch
    bulk_payload = ids.map { |id| { delete: { _index: index, _id: id } } }
    response = Event.__elasticsearch__.client.bulk(body: bulk_payload)
    Rails.logger.info("#{label}: #{response}")
  rescue => err
    Rails.logger.error("#{label}: #{are.message}")
  end
end
