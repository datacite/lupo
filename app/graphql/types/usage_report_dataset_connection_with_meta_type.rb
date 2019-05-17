# frozen_string_literal: true

class UsageReportDatasetConnectionWithMetaType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    Event.query(nil, subj_id: object.parent[:id]).dig(:meta, "total").to_i
  end
end
