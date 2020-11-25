# frozen_string_literal: true

class OrcidAutoUpdateJob < ApplicationJob
  queue_as :lupo_background

  def perform(ids, options = {})
    ids.each { |id| OrcidAutoUpdateByIdJob.perform_later(id, options) }
  end
end
