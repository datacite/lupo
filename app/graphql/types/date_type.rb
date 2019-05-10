# frozen_string_literal: true

module Types
  class DateType < Types::BaseObject
    description "Information about dates"

    field :date, String, null: true, description: "Any rights information for this resource"
    field :date_type, String, null: true, hash_key: "dateType", description: "The type of date"
  end
end
