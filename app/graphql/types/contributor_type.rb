# frozen_string_literal: true

class ContributorType < BaseObject
  description "A contributor."

  field :id, ID, null: true, description: "The ID of the contributor."
  field :type, String, null: false, description: "The type of the item."
  field :contributor_type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the contributor."
  field :given_name, String, null: true, description: "Given name. In the U.S., the first name of a person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an person."
  field :affiliation, [AffiliationType], null: true, description: "The organizational or institutional affiliation of the contributor."

  def type
    object.name_type == "Organizational" ? "Organization" : "Person"
  end
end
