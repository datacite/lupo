# frozen_string_literal: true

module Types
  class CountryType < Types::BaseObject
    description "Information about countries"

    field :id, String, null: false, description: "Country code"
    field :name, String, null: true, description: "Country name"
  end
end
