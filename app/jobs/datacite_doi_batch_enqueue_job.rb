
# frozen_string_literal: true

class DataciteDoiBatchEnqueueJob < ApplicationJob
  queue_as :lupo_queue_batches_datacite_doi

  def perform(start_id, end_id, batch_size: 50, index: nil)
    # GOT HERE!!!!
    Rails.logger.info "ZZZZ: Enqueuing DataciteDoiImportInBulkJob for DataciteDois with IDs #{start_id}-#{end_id} in batches of #{batch_size} to index #{index}."
    ids = DataciteDoi.where(type: "DataciteDoi", id: start_id..end_id).pluck(:id)
    ids.each_slice(batch_size) do |batch_ids|
      # GOT HERE!!!!
      Rails.logger.info "ZZZZ: Enqueuing DataciteDoiImportInBulkJob for batch of DataciteDois with IDs #{batch_ids.first}-#{batch_ids.last} to index #{index}."
      DataciteDoiImportInBulkJob.perform_later(batch_ids, index: index)
    end
  end
end
