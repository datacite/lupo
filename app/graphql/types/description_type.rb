# frozen_string_literal: true

class DescriptionType < BaseObject
  description "Information about descriptions"

  field :description, String, null: true, description: "Description"
  field :description_type,
        String,
        null: true, description: "Description type"

  def description_type
    object["descriptionType"]
  end

  field :lang, ID, null: true, description: "Language"
end
