# frozen_string_literal: true

class DoiBatchProcessJob < ApplicationJob
  queue_as :lupo_doi_batch

  CHUNK_SIZE = 50

  def perform(batch_id)
    batch = DoiBatch.find(batch_id)
    return if batch.completed?

    batch.mark_processing!
    batch.items.where.not(status: DoiBatchItem::TERMINAL_STATUSES).
      order(:position).
      pluck(:id).
      each_slice(CHUNK_SIZE) do |item_ids|
        DoiBatchChunkJob.perform_later(item_ids)
      end
  end
end
