# frozen_string_literal: true

class SchemeType < BaseObject
  description "Information"

  field :scheme, String, null: false, description: "Schema"
  field :text, String, null: false, description: "Information"
end
