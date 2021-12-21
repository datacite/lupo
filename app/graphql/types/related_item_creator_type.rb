# frozen_string_literal: true

class RelatedItemCreatorType < BaseObject
  description "A creator of a related item"

  field :name_type,
        String,
        null: true,
        hash_key: "nameType",
        description: "The type of name."
  field :name,
        String,
        null: false,
        hash_key: "creatorName"
        description: "The name of the creator."
  field :given_name,
        String,
        null: true,
        hash_key: "givenName",
        description: "Given name. In the U.S., the first name of a Person."
  field :family_name,
        String,
        null: true,
        hash_key: "familyName",
        description: "Family name. In the U.S., the last name of an Person."
  
  def type
    case object.name_type
    when "Organizational"
      "Organization"
    when "Personal"
      "Person"
    end
  end
end
