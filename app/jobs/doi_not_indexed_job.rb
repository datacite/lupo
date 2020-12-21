# frozen_string_literal: true

class DoiNotIndexedJob < ApplicationJob
  queue_as :lupo_background

  def perform(client_id, _options = {})
    Doi.import_by_ids(model: "Client", client_id: client_id)
  end
end
