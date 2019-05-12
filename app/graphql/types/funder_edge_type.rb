# frozen_string_literal: true

class FunderEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(FunderType)
end
