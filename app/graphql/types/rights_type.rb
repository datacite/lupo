# frozen_string_literal: true

class RightsType < BaseObject
  description "Information about rights"

  field :rights,
        String,
        null: true, description: "Any rights information for this resource."
  field :rights_uri,
        String,
        null: true,
        hash_key: "rightsUri",
        description: "The URI of the license."
  field :rights_identifier,
        String,
        null: true,
        hash_key: "rightsIdentifier",
        description: "A short, standardized version of the license name."
  field :rights_identifier_scheme,
        String,
        null: true,
        hash_key: "rightsIdentifierScheme",
        description: "The name of the scheme."
  field :scheme_uri,
        String,
        null: true,
        hash_key: "schemeUri",
        description: "The URI of the rightsIdentifierScheme."
  field :lang, String, null: true, description: "Language"
end
