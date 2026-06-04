# frozen_string_literal: true

class RelatedItemContributorType < BaseObject
  description "A contributor to a related item"

  field :contributor_type,
        String,
        null: true,
        description: "The type of contributor."

  def contributor_type
    object["contributorType"]
  end

  field :name,
        String,
        null: false,
        description: "The name of the contributor."

  def name
    object["contributorName"]
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
        description: "Family name. In the U.S., the last name of a Person."

  def family_name
    object["familyName"]
  end

  def type
    case object.name_type
    when "Organizational"
      "Organization"
    when "Personal"
      "Person"
    end
  end
end
