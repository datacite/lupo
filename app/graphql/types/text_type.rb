# frozen_string_literal: true

module Types
  class TextType < Types::BaseObject
    description "Information"

    field :text, String, null: false, description: "Information"
  end
end
