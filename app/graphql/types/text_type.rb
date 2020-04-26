# frozen_string_literal: true

class Types::TextType < Types::BaseObject
  description "Information"

  field :text, String, null: false, description: "Information"
end
