# frozen_string_literal: true

class RelatedItemContributorType < BaseObject
  description "A contributor to a related item"

  field :contributor_type,
        String,
        null: true,
        hash_key: "contributorType",
        description: "The type of contributor."
  field :name,
        String,
        null: false,
        hash_key: "contributorName",
        description: "The name of the contributor."
  field :given_name,
        String,
        null: true,
        hash_key: "givenName",
        description: "Given name. In the U.S., the first name of a Person."
  field :family_name,
        String,
        null: true,
        hash_key: "familyName",
        description: "Family name. In the U.S., the last name of a Person."

  def type
    case object.name_type
    when "Organizational"
      "Organization"
    when "Personal"
      "Person"
    end
  end
end
