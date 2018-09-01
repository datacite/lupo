class DoiIndexByDayJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.index_by_day(options)
  end
end