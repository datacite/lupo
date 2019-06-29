class OrcidAutoUpdateJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids)
    ids.each { |id| OrcidAutoUpdateByIdJob.perform_later(id) }
  end
end
