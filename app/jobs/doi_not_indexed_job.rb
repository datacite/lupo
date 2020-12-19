# frozen_string_literal: true

class DoiNotIndexedJob < ApplicationJob
  queue_as :lupo_background

  def perform(client_id, options = {})
    Doi.import_by_client(client_id, options)
  end
end
