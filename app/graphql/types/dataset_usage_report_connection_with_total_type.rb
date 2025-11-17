# frozen_string_literal: true

class DatasetUsageReportConnectionWithTotalType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)

  field :total_count, Integer, null: false

  def total_count
    Event.query(nil, obj_id: object.parent.id).results.total
  end
end
