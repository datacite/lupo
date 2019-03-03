class ActivityIndexByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(options={})
    Activity.index_by_id(options)
  end
end