class ImportDoiJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id, _options = {})
    Doi.import_one(doi_id: doi_id)
  end
end
