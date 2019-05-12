# frozen_string_literal: true

class FunderDatasetConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)

  field :total_count, Integer, null: false

  def total_count
    Event.query(nil, obj_id: object[:id], citation_type: "Dataset-Funder").fetch(:meta, "total")
  end
end
