module Types
  class ResearcherType < Types::BaseObject
    description "Information about researchers"

    field :id, ID, null: false, description: "ORCID ID"
    field :name, String, null: true, description: "Researcher name"
    field :given_name, String, null: true, description: "Researcher given name"
    field :family_name, String, null: true, description: "Researcher family name"
  end
end