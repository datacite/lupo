class CamelcaseNestedObjectsByIdJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(uuid, options = {})
    Event.camelcase_nested_objects(uuid)
  end
end
