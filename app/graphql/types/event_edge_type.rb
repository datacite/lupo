# frozen_string_literal: true

class Types::EventEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::EventType)
end
