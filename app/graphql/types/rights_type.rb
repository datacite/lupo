# frozen_string_literal: true

module Types
  class RightsType < Types::BaseObject
    description "Information about rights"

    field :rights, String, null: true, description: "Any rights information for this resource"
    field :rights_uri, String, null: true, hash_key: "rightsUri", description: "The URI of the license"
    field :lang, String, null: true, description: "Language"
  end
end
