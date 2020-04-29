# frozen_string_literal: true

module Types
  class CountryType < Types::BaseObject
    description "Information about countries"

    field :code, String, null: true, description: "Country ISO 3166-1 code"
    field :name, String, null: true, description: "Country name"
  end
end
