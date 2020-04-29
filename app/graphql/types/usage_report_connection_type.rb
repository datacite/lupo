# frozen_string_literal: true

module Types
  class UsageReportConnectionType < Types::BaseConnection
    edge_type(Types::UsageReportEdgeType)
    field_class GraphQL::Cache::Field
    
    field :total_count, Integer, null: false, cache: true

    def total_count
      UsageReport.query(nil, limit: 0).dig(:meta, "total").to_i
    end
  end
end
