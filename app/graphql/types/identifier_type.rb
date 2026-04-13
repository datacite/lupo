# frozen_string_literal: true

class IdentifierType < BaseObject
  description "Information about identifiers"

  field :identifier_type,
        String,
        null: true,
        description: "The type of identifier."

  def identifier_type
    object["identifierType"]
  end

  field :identifier,
        String,
        null: true, description: "The value of the identifier."
  field :identifier_url,
        String,
        null: true,
        description: "The url of the identifier."

  def identifier_url
    object["identifierUrl"]
  end
end
