# frozen_string_literal: true

class TitleType < BaseObject
  description "Information about titles"

  field :title, String, null: true, description: "Title"
  field :title_type,
        String,
        null: true, description: "Title type"

  def title_type
    object["titleType"]
  end

  field :lang, ID, null: true, description: "Language"
end
