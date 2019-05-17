# frozen_string_literal: true

class UsageReportType < BaseObject
  description "Information about usage reports"

  field :id, ID, null: false, description: "Usage report ID"
  field :reporting_period, ReportingPeriodType, null: false, description: "Time period covered by the report"
  field :date_created, String, null: false, description: "Date information was created"
  field :datasets, UsageReportDatasetConnectionWithMetaType, null: false, description: "Datasets included in usage report", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def datasets(**args)
    ids = Event.query(nil, subj_id: object[:id], source_id: "datacite-usage").fetch(:data, []).map do |e|
      doi_from_url(e[:obj_id])
    end
    ElasticsearchLoader.for(Doi).load_many(ids)
  end
end
