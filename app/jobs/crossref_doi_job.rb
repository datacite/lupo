class CrossrefDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids)
    ids.each { |id| CrossrefDoiByIdJob.perform_later(id) }
  end
end
