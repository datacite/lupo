# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    ids = event.dois_to_import
    Rails.logger.info("OtherDoiJob: ids: #{ids.inspect}")
    ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
