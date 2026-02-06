# frozen_string_literal: true

class DataciteDoiImportInBulkJob < ApplicationJob
  queue_as :lupo_import

  def perform(ids, options = {})
    # GOT HERE!!!!
    Rails.logger.info "ZZZZ: Starting DataciteDoiImportInBulkJob for DataciteDois with IDs #{ids.first}-#{ids.last} to index #{options[:index]}."
    DataciteDoi.import_in_bulk(ids, options)
  end
end
