# frozen_string_literal: true

class OtherDoiImportInBulkJob < ApplicationJob
  include ResolvesElasticsearchIndex

  queue_as :lupo_import_other_doi

  def perform(ids, options = {})
    resolved = resolve_options_index(OtherDoi, options)
    return if resolved.nil?

    OtherDoi.import_in_bulk(ids, resolved)
  end
end
