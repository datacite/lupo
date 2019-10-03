# frozen_string_literal: true

class IdentifierType < BaseObject
  description "Information about identifiers"

  field :name, String, null: true, description: "The name of the identifier."
  field :value, String, null: true, description: "The value of the identifier."
end
