# frozen_string_literal: true

module Types
  class NameType < Types::BaseObject
    description "Information"

    field :name, String, null: false, description: "Information"
  end
end
