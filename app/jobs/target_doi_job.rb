# frozen_string_literal: true

class TargetDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options={})
    ids.each { |id| TargetDoiByIdJob.perform_later(id, options) }
  end
end
