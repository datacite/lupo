# frozen_string_literal: true

class ReindexByDoiJob < ApplicationJob
  include Shoryuken::Worker

  queue_as :lupo_background
  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_lupo_background" }, auto_delete: true

  def perform(sqs_message = nil, doi_id = nil)
    doi = Doi.find_by(doi: doi_id)
    return unless doi.present?

    if doi.agency == "datacite"
      DataciteDoiImportInBulkJob.perform_later([doi.id], index: DataciteDoi.active_index)
    else
      OtherDoiImportInBulkJob.perform_later([doi.id], index: OtherDoi.active_index)
    end
  end
end
