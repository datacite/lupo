# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    Rails.logger.info("#######################")
    Rails.logger.info(data)
    event = Event.new(subj_id: body["subj_id"], obj_id: body["obj_id"])
    ids = event.dois_to_import
    Rails.logger.info(ids.inspect)
    Rails.logger.info("#######################")
    # ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
