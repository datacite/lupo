
class FlattenedCountType < BaseObject
  description "Flattened Count Type for Multi-level Facets"

  field :count, Int, null: true, description: "Count"
  field :data, [String], null: true, description: "Flattened facets"
end
