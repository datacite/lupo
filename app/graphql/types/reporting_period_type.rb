# frozen_string_literal: true

class ReportingPeriodType < BaseObject
  description "Information about reporting periods"

  field :begin_date, String, null: true, description: "Begin reporting period"
  field :end_date, String, null: true, description: "End reporting period"
end
