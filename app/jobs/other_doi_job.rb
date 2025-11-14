# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    ids = event.dois_to_import
    Rails.logger.info("OtherDoiJob: dois that should be created: #{ids}")
    ids.each do |id|
      Rails.logger.info("OtherDoiJob: sending #{doi} to OtherDoiByIdJob")
      OtherDoiByIdJob.perform_later(id, {})
    end
  end
end
