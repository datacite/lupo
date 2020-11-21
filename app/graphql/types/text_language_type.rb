# frozen_string_literal: true

class TextLanguageType < BaseObject
  description "Information"

  field :language, String, null: true, description: "Language"
  field :text, String, null: false, description: "Information"
end
