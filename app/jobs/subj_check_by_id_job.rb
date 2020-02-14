class SubjCheckByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(event, options = {})
      subj_prefix = event[:subj_id][/(10\.\d{4,5})/, 1]
      if Prefix.where(prefix: subj_prefix).exists?
        Event.find_by(id: event[:id]).update_attribute(:state_event, "subj_id_error")
      end
  end
end
