# frozen_string_literal: true

class DatasetType < BaseObject
  implements DoiItem

  field :usage_reports,
        DatasetUsageReportConnectionWithTotalType,
        null: false,
        description: "Usage reports for this dataset",
        connection: true

  def usage_reports(**args)
    ids =
      Event.query(nil, obj_id: object.id).results.to_a.map { |e| e[:subj_id] }
    UsageReport.find_by_id(ids, page: { number: 1, size: args[:first] }).fetch(
      :data,
      [],
    )
  end
end
