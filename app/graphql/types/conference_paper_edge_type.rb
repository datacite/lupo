# frozen_string_literal: true

module Types
  class ConferencePaperEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::ConferencePaperType)
  end
end
