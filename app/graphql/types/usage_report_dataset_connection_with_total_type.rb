# frozen_string_literal: true

class UsageReportDatasetConnectionWithTotalType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)

  field :total_count, Integer, null: false

  def total_count
    Event.query(nil, subj_id: object.parent[:id]).results.total
  end
end
