# frozen_string_literal: true

class ReindexByDoiJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id, _options = {})
    doi = Doi.find_by(doi: doi_id)
    return unless doi.present?

    if doi.agency == "datacite"
      DataciteDoiImportInBulkJob.perform_later([doi.id], index: DataciteDoi.active_index)
    else
      OtherDoiImportInBulkJob.perform_later([doi.id], index: OtherDoi.active_index)
    end
  end
end
