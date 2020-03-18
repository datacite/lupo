class CamelcaseNestedObjectsJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(ids, options = {})
    ids.each { |id| CamelcaseNestedObjectsByIdJob.perform_later(id, options) }
  end
end
