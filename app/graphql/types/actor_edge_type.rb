# frozen_string_literal: true

class ActorEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ActorItem)
end
