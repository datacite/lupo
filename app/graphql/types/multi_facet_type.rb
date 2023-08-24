# frozen_string_literal: true

class MultiFacetType < BaseObject
  description "Multi-level Facets"

  field :id, String, null: true, description: "ID"
  field :title, String, null: true, description: "Title"
  field :count, Int, null: true, description: "Count"
  field :inner, [FacetType], null: true, description: "Inner facets"
end
