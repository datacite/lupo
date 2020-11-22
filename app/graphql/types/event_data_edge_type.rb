# frozen_string_literal: true

class EventDataEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(EventDataType)

  field :source_id,
        String,
        null: true, description: "The source ID of the event."
  field :target_id,
        String,
        null: true, description: "The target ID of the event."
  field :source, String, null: true, description: "Source for this event"
  field :relation_type,
        String,
        null: true, description: "Relation type for this event."
  field :total, Integer, null: true, description: "Total count for this event."
end
