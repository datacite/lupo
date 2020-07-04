# frozen_string_literal: true

class LanguageType < BaseObject
  description "Information about languages"

  field :id, ID, null: true, description: "Language ISO 639-1 code"
  field :name, String, null: true, description: "Language name"
end
