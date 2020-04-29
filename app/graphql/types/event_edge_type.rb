# frozen_string_literal: true

module Types
  class EventEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::EventType)
  end
end
