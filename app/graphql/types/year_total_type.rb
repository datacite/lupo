# frozen_string_literal: true

module Types
  class YearTotalType < Types::BaseObject
    description "Information about totals over time (years)"

    field :year, Int, null: true, description: "Year"
    field :total, Int, null: true, description: "Total"
  end
end
