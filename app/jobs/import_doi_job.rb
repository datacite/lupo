class ImportDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(doi_id, options={})
    Doi.import_one(doi_id: doi_id)
  end
end
