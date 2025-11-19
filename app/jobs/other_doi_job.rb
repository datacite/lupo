# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(sqs_message = nil, data = nil)
    data = JSON.parse(data)
    Rails.logger.info("OtherDoiJob: Start of other doi job for data: #{data.inspect}")
    Rails.logger.info("subj_id: #{data["subj_id"]}")
    Rails.logger.info("obj_id: #{data["obj_id"]}")
    event = Event.new(subj_id: data["subj_id"], obj_id: data["obj_id"])
    Rails.logger.info("event.subj_id: #{event.subj_id}")
    Rails.logger.info("event.obj_id: #{event.obj_id}")
    ids = event.dois_to_import
    Rails.logger.info("OtherDoiJob: dois that should be created: #{ids}")
    ids.each do |id|
      Rails.logger.info("OtherDoiJob: #{id} will be processed by the OtherDoiByIdJob")
      OtherDoiByIdJob.perform_later(id, {})
    rescue => error
      Rails.logger.error("OtherDoiJob: Error: #{error}")
    end
  end
end
