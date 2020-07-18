# frozen_string_literal: true

class FieldOfScienceType < BaseObject
  description "Information about OECD Fields of Science"

  field :id, ID, null: true, description: "Fields of Science id"
  field :name, String, null: true, description: "Fields of Science name"
end
