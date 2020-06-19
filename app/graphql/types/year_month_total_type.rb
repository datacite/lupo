# frozen_string_literal: true

class YearMonthTotalType < BaseObject
  description "Information about totals over time (years)"

  field :year_month, String, null: true, hash_key: :yearMonth, description: "Year-month"
  field :total, Int, null: true, description: "Total"
end
