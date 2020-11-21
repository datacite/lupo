class EventImportByIdJob < ApplicationJob
  queue_as :lupo_background

  def perform(options = {})
    Event.import_by_id(options)
  end
end
