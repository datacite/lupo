# frozen_string_literal: true

module Types
  class FacetType < Types::BaseObject
    description "Summary information"

    field :id, String, null: true, description: "ID"
    field :title, String, null: true, description: "Title"
    field :count, Int, null: true, description: "Count"
  end
end
