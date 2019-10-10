# frozen_string_literal: true

class EventDataEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(EventDataType)

  field :source_id, String, null: false, description: "The source ID of the event."
  field :target_id, String, null: false, description: "The target ID of the event."
  field :source, String, null: false, description: "Source for this event"
  field :relation_type, String, null: false, description: "Relation type for this event."
  field :total, Integer, null: false, description: "Total count for this event."
end
