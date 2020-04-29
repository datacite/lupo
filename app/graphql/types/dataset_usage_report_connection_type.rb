# frozen_string_literal: true

module Types
  class DatasetUsageReportConnectionType < Types::BaseConnection
    edge_type(Types::EventDataEdgeType, edge_class: EventDataEdge)
    field_class GraphQL::Cache::Field
    
    field :total_count, Integer, null: false, cache: true

    def total_count
      Event.query(nil, obj_id: object.parent.id).results.total
    end
  end
end
