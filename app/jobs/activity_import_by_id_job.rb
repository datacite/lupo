class ActivityImportByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Activity.import_by_id(options)
  end
end