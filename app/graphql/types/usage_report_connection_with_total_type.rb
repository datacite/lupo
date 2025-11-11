# frozen_string_literal: true

class UsageReportConnectionWithTotalType < BaseConnection
  edge_type(UsageReportEdgeType)

  field :total_count, Integer, null: false, cache_fragment: true

  def total_count
    UsageReport.query(nil, limit: 0).dig(:meta, "total").to_i
  end
end
