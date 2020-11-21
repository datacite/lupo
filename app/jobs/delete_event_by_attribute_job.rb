class DeleteEventByAttributeJob < ApplicationJob
  queue_as :lupo_background

  def perform(id, options = {})
    Event.where({ uuid: id }.merge(options)).destroy_all
  end
end
