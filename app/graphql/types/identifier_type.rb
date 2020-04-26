# frozen_string_literal: true

class Types::IdentifierType < Types::BaseObject
  description "Information about identifiers"

  field :identifier_type, String, null: true, description: "The type of identifier."
  field :identifier, String, null: true, description: "The value of the identifier."
end
