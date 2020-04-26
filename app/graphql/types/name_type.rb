# frozen_string_literal: true

class Types::NameType < Types::BaseObject
  description "Information"

  field :name, String, null: false, description: "Information"
end
