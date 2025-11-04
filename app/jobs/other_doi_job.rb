# frozen_string_literal: true

class OtherDoiJob < ApplicationJob
  include Shoryuken::Worker

  shoryuken_options queue: -> { "#{ENV["RAILS_ENV"]}_events_other_doi_job" }, auto_delete: true

  def perform(data, options = {})
    # to test in staging
    Rails.logger.info("#######################")
    Rails.logger.info("the other doi job has run")
    Rails.logger.info("#######################")
    Rails.logger.info(data.inspect)
    Rails.logger.info("#######################")
    json_data = JSON.parse(data["body"])
    event = Event.new(subj_id: json_data["subj_id"], obj_id: json_data["obj_id"])
    ids = event.dois_to_import
    Rails.logger.info(ids.inspect)
    Rails.logger.info("#######################")
    ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
