# frozen_string_literal: true

class DataciteDoiImportInBulkJob < ApplicationJob
  queue_as :lupo_import

  def perform(ids, options = {})
    DataciteDoi.import_in_bulk(ids, options)
  end
end
