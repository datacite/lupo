# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    Rails.logger.info(event)
    ids = event.dois_to_import
    ids = ["fake_doi_1", "fake_doi_2"]
    ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
