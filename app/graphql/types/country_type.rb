# frozen_string_literal: true

class CountryType < BaseObject
  description "Information about countries"

  field :id, String, null: true, description: "Country code"
  field :name, String, null: true, description: "Country name"
end
