# frozen_string_literal: true

class DoiEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(DoiItem)
end
