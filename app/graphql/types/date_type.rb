# frozen_string_literal: true

class DateType < BaseObject
  description "Information about dates"

  field :date, String, null: false, description: "Date information for this resource"
  field :date_type, String, null: true, hash_key: "dateType", description: "The type of date"
end
