# frozen_string_literal: true

class OtherDoiBatchEnqueueJob < ApplicationJob
  queue_as :lupo_import_other_doi

  def perform(start_id, end_id, batch_size: 50, index: nil)
    ids = OtherDoi.where(type: "OtherDoi", id: start_id..end_id).pluck(:id)
    ids.each_slice(batch_size) do |batch_ids|
      OtherDoiImportInBulkJob.perform_later(batch_ids, index: index)
    end
  end
end
