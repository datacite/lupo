# frozen_string_literal: true

class UsageReportDatasetConnectionType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    Event.query(nil, subj_id: object.parent[:id]).results.total
  end
end
