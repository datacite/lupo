# frozen_string_literal: true

class AffiliationType < BaseObject
  description "Information about affiliations"

  field :id, ID, null: true, description: "Unique identifier for each affiliation"
  field :name, String, null: true, description: "Affiliation name"
end
