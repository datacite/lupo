# frozen_string_literal: true

module Types
  class FunderEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::FunderType)
  end
end
