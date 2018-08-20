class DoiIndexByMonthJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Doi.index(options)
  end
end