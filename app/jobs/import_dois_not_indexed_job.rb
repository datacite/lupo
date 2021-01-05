# frozen_string_literal: true

class ImportDoisNotIndexedJob < ApplicationJob
  queue_as :lupo_background

  def perform(query, _options = {})
    Client.import_dois_not_indexed(query: query)
  end
end
