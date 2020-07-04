# frozen_string_literal: true

class RegistrationAgencyType < BaseObject
  description "Information about DOI registration agencies"

  field :id, ID, null: true, description: "DOI registration agency id"
  field :name, String, null: true, description: "DOI registration agency name"
end
