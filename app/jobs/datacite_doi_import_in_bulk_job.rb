# frozen_string_literal: true

class DataciteDoiImportInBulkJob < ApplicationJob
  include ResolvesElasticsearchIndex

  queue_as :lupo_import

  def perform(ids, options = {})
    resolved = resolve_options_index(DataciteDoi, options)
    return if resolved.nil?

    DataciteDoi.import_in_bulk(ids, resolved)
  end
end
