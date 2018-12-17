class DoiImportByDayMissingJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.import_by_day_missing(options)
  end
end