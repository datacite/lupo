# frozen_string_literal: true

class RelatedItemCreatorType < BaseObject
  description "A creator of a related item"

  field :name_type,
        String,
        null: true,
        description: "The type of name."

  def name_type
    object["nameType"]
  end

  field :name,
        String,
        null: false,
        description: "The name of the creator."

  def name
    object["creatorName"]
  end

  field :given_name,
        String,
        null: true,
        description: "Given name. In the U.S., the first name of a Person."

  def given_name
    object["givenName"]
  end

  field :family_name,
        String,
        null: true,
        description: "Family name. In the U.S., the last name of an Person."

  def family_name
    object["familyName"]
  end

  def type
    case object["nameType"]
    when "Organizational"
      "Organization"
    when "Personal"
      "Person"
    end
  end
end
