# frozen_string_literal: true

class IdentifierType < BaseObject
  description "Information about identifiers"

  field :identifier_type,
        String,
        null: true,
        hash_key: "identifierType",
        description: "The type of identifier."
  field :identifier,
        String,
        null: true, description: "The value of the identifier."
  field :identifier_url,
        String,
        null: true,
        hash_key: "identifierUrl",
        description: "The url of the identifier."
end
