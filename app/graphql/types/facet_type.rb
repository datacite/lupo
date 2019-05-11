# frozen_string_literal: true

class FacetType < BaseObject
  description "Summary information"

  field :id, String, null: true, description: "ID"
  field :title, String, null: true, description: "Title"
  field :count, Int, null: true, description: "Count"
end
