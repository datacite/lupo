# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    data = JSON.parse(data)
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    ids = event.dois_to_import
    ids.each do |id|
      OtherDoiByIdJob.perform_later(id, {})
    end
  end
end
