class DoiImportByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.import_by_id(options)
  end
end