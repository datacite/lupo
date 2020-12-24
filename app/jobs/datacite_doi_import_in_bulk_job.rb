# frozen_string_literal: true

class DataciteDoiImportInBulkJob < ApplicationJob
  queue_as :lupo_import

  def perform(dois, options = {})
    DataciteDoi.import_in_bulk(dois, options)
  end
end
