# frozen_string_literal: true

class EventEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(EventType)
end
