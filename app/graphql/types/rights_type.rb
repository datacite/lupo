# frozen_string_literal: true

class RightsType < BaseObject
  description "Information about rights"

  field :rights,
        String,
        null: true, description: "Any rights information for this resource."
  field :rights_uri,
        String,
        null: true,
        description: "The URI of the license."

  def rights_uri
    object["rightsUri"]
  end

  field :rights_identifier,
        String,
        null: true,
        description: "A short, standardized version of the license name."

  def rights_identifier
    object["rightsIdentifier"]
  end

  field :rights_identifier_scheme,
        String,
        null: true,
        description: "The name of the scheme."

  def rights_identifier_scheme
    object["rightsIdentifierScheme"]
  end

  field :scheme_uri,
        String,
        null: true,
        description: "The URI of the rightsIdentifierScheme."

  def scheme_uri
    object["schemeUri"]
  end

  field :lang, String, null: true, description: "Language"
end
