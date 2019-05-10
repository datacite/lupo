# frozen_string_literal: true

module Types
  class IdentifierType < Types::BaseObject
    description "Information about identifiers"

    field :identifier, String, null: true, description: "Identifier"
    field :identifier_type, String, null: true, hash_key: "identifierType", description: "Identifier type"
  end
end
