# frozen_string_literal: true

class DataciteDoiImportInBulkJob < ApplicationJob
  queue_as :lupo_import_other_doi

  def perform(dois, options = {})
    OtherDoi.import_in_bulk(dois, options)
  end
end
