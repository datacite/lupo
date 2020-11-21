class CamelcaseNestedObjectsByIdJob < ApplicationJob
  queue_as :lupo_background

  def perform(uuid, _options = {})
    Event.camelcase_nested_objects(uuid)
  end
end
