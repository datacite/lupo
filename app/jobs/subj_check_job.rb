class SubjCheckJob < ApplicationJob
  queue_as :lupo_background

  def perform(events, options = {})
    events.each { |event| SubjCheckByIdJob.perform_later(event, options) }
  end
end
