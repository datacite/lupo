class DoiImportByDayJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.import_by_day(options)
  end
end