module Types
  class ResearcherType < Types::BaseObject
    description "Information about researchers"

    field :id, ID, null: true, description: "ORCID ID"
    field :name, String, null: true, description: "Researcher name"
    field :name_type, String, null: true, hash_key: "nameType", description: "The type of name"
    field :given_name, String, null: true, hash_key: "givenName", description: "Researcher given name"
    field :family_name, String, null: true, hash_key: "familyName", description: "Researcher family name"
    field :affiliation, [String], null: true, description: "Researcher affiliation"
  end
end