# frozen_string_literal: true

module Types
  class WorkEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::WorkType)
  end
end
