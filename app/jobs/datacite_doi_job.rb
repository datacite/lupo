class DataciteDoiJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options={})
    ids.each { |id| DataciteDoiByIdJob.perform_later(id, options) }
  end
end
