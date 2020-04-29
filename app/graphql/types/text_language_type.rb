# frozen_string_literal: true

module Types
  class TextLanguageType < Types::BaseObject
    description "Information"
    
    field :language, String, null: true, description: "Language"
    field :text, String, null: false, description: "Information"
  end
end
