class DeleteEventByAttributeJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options = {})
    ids.each do |id|
      Event.where({ uuid: id }.merge(options)).destroy_all
    end
  end
end
