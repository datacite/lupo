# frozen_string_literal: true

class IdentifierType < BaseObject
  description "Information about identifiers"

  field :identifier, String, null: true, description: "Identifier"
  field :identifier_type, String, null: true, hash_key: "identifierType", description: "Identifier type"
end
