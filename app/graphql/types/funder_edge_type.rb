# frozen_string_literal: true

class Types::FunderEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::FunderType)
end
