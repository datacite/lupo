# frozen_string_literal: true

class OtherDoiImportInBulkJob < ApplicationJob
  queue_as :lupo_import_other_doi

  def perform(ids, options = {})
    OtherDoi.import_in_bulk(ids, options)
  end
end
