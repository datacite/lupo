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
    sql = ActiveRecord::Base.sanitize_sql_array(["DELETE FROM events WHERE id IN (?)", ids])
    ActiveRecord::Base.connection.execute(sql)

    # delete event documents from elasticsearch
    bulk_payload = ids.map { |id| { delete: { _index: index, _id: id } } }
    Event.__elasticsearch__.client.bulk(body: bulk_payload)
  rescue => err
    Rails.logger.error("#{label}: #{err.message}")
  end
end
