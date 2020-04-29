# frozen_string_literal: true

module Types
  class TextRestrictionType < Types::BaseObject
    description "Information"
    
    field :text, String, null: false, description: "Information"
    field :restriction, [TextType], null: true, description: "Restriction"
  end
end
