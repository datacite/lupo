# frozen_string_literal: true

class DatasetType < BaseObject
  implements DoiItem

  field :usage_reports, DatasetUsageReportConnectionWithMetaType, null: false, description: "Usage reports for this dataset", connection: true, max_page_size: 100 do
    argument :first, Int, required: false, default_value: 25
  end

  def usage_reports(**args)
    ids = Event.query(nil, obj_id: object.id).results.to_a.map do |e|
      e[:subj_id]
    end
    UsageReport.find_by_id(ids, page: { number: 1, size: args[:first] }).fetch(:data, [])
  end
end
