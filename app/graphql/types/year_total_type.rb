# frozen_string_literal: true

class YearTotalType < BaseObject
  description "Information about totals over time (years)"

  field :year, Int, null: true, description: "Year"
  field :total, Int, null: true, description: "Total"
end
