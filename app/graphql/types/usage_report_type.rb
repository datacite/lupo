# frozen_string_literal: true

module Types
  class UsageReportType < Types::BaseObject
    description "Information about usage reports"

    field :id, ID, null: false, description: "Usage report ID"
    field :repository_id, String, null: true, description: "Repository that created the report"
    field :reporting_period, Types::ReportingPeriodType, null: false, description: "Time period covered by the report"
    field :date_created, String, null: false, description: "Date information was created"
    field :datasets, Types::UsageReportDatasetConnectionType, null: false, description: "Datasets included in usage report", connection: true do
      argument :first, Int, required: false, default_value: 25
    end

    def datasets(**args)
      ids = Event.query(nil, subj_id: object[:id]).results.to_a.map do |e|
        doi_from_url(e[:obj_id])
      end
      ElasticsearchLoader.for(Doi).load_many(ids)
    end

    def doi_from_url(url)
      if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, "").downcase
      end
    end
  end
end
