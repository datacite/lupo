# frozen_string_literal: true

module ActorItem
  include BaseInterface
  include Bolognese::MetadataUtils

  description "Information about people, research organizations and funders"

  field :id, ID, null: false, description: "The persistent identifier for the actor."
  field :type, String, null: false, description: "The type of the actor."
  field :name, String, null: true, description: "The name of the actor."
  field :alternate_name, [String], null: true, description: "An alias for the actor."

  definition_methods do
    # Determine what object type to use for `object`
    def resolve_type(object, context)
      if object.type == "Person"
        PersonType
      elsif object.type == "Organization"
        OrganizationType
      elsif object.type == "Funder"
        FunderType
      else
        raise "Unexpected Actor: #{object.inspect}"
      end
    end
  end
end
