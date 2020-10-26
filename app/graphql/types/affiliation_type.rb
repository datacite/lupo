# frozen_string_literal: true

class AffiliationType < BaseObject
  description "Information about affiliations"

  field :id, ID, null: true, description: "Affiliation identifier"
  field :name, String, null: true, description: "Affiliation name"
end
