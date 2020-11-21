class DoiJob < ApplicationJob
  queue_as :lupo_background

  def perform(ids, options = {})
    ids.each { |id| DoiByIdJob.perform_later(id, options) }
  end
end
