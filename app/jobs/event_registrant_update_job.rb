class EventRegistrantUpdateJob < ApplicationJob
  queue_as :lupo_background

  def perform(ids, options = {})
    ids.each { |id| EventRegistrantUpdateByIdJob.perform_later(id, options) }
  end
end
