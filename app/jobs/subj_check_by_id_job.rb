class SubjCheckByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(event, options = {})
    Event.label_state_event(event)
  end
end
