# frozen_string_literal: true

class Types::WorkEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::WorkType)
end
