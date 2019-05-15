# frozen_string_literal: true

class CountryType < BaseObject
  description "Information about countries"

  field :code, String, null: true, description: "Country ISO 3166-1 code"
  field :name, String, null: true, description: "Country name"
end
