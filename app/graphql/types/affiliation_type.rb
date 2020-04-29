# frozen_string_literal: true

module Types
  class AffiliationType < Types::BaseObject
    description "Information about affiliations"

    field :id, ID, null: true, description: "Affiliation ROR identifier"
    field :name, String, null: false, description: "Affiliation name"
  end
end
