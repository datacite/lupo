# frozen_string_literal: true

class UsageReportType < BaseObject
  description "Information about usage reports"

  field :id, ID, null: false, description: "Usage report ID"
  field :reporting_period, ReportingPeriodType, null: false, description: "Time period covered by the report"
  field :date_created, String, null: false, description: "Date information was created"
end
