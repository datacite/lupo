class SubjCheckByIdJob < ApplicationJob
  queue_as :lupo_background

  def perform(event, _options = {})
    Event.label_state_event(event)
  end
end
