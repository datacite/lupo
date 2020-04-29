# frozen_string_literal: true

module Types
  class UsageReportDatasetConnectionType < Types::BaseConnection
    edge_type(Types::EventDataEdgeType, edge_class: Types::EventDataEdge)
    field_class GraphQL::Cache::Field
    
    field :total_count, Integer, null: false, cache: true

    def total_count
      Event.query(nil, subj_id: object.parent[:id]).results.total
    end
  end
end
