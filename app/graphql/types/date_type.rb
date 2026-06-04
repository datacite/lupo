# frozen_string_literal: true

class DateType < BaseObject
  description "Information about dates"

  field :date,
        String,
        null: false, description: "Date information for this resource"
  field :date_type,
        String,
        null: true, description: "The type of date"

  def date_type
    object["dateType"]
  end
end

# Acceptable values for date_type are from the DataCite Metadata Schema:
# Accepted Available Copyrighted Collected Created Issued Submitted Updated
# Valid Withdrawn Other
