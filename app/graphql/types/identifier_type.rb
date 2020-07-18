# frozen_string_literal: true

class IdentifierType < BaseObject
  description "Information about identifiers"

  field :identifier_type, String, null: false, hash_key: "identifierType", description: "The type of identifier."
  field :identifier, String, null: false, description: "The value of the identifier."
end
