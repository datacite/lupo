# frozen_string_literal: true

class DoiImportByClientJob < ApplicationJob
  queue_as :lupo_background

  def perform(client_id, _options = {})
    DataciteDoi.import_by_client(client_id)
  end
end
