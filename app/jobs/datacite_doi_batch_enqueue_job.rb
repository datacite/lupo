
# frozen_string_literal: true

class DataciteDoiBatchEnqueueJob < ApplicationJob
  queue_as :lupo_queue_batches_datacite_doi

  def perform(start_id, end_id, batch_size = 50, index = nil)
    ids = DataciteDoi.where(type: "DataciteDoi", id: start_id..end_id).pluck(:id)
    ids.each_slice(batch_size) do |batch_ids|
      DataciteDoiImportInBulkJob.perform_later(batch_ids, index: index)
    end
  end
end
