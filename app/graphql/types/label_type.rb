# frozen_string_literal: true

class LabelType < BaseObject
  description "Information about labels"

  field :iso639, ID, null: false, description: "Label language"
  field :name, String, null: true, method: :label, description: "Label name"
end
