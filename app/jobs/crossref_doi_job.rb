class CrossrefDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options={})
    ids.each { |id| CrossrefDoiByIdJob.perform_later(id, options) }
  end
end
