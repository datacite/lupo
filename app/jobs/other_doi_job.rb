# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  queue_as :events_other_doi_job

  def perform(data, options = {})
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    ids = event.dois_to_import
    ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
