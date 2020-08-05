class OtherDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options={})
    ids.each { |id| OtherDoiByIdJob.perform_later(id, options) }
  end
end
