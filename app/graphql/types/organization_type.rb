module Types
  class OrganizationType < Types::BaseObject
    description "Information about organizations"

    field :id, ID, null: false, description: "ROR identifier"
    field :name, String, null: false, description: "Organization name"
  end
end
