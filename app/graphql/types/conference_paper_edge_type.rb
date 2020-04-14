# frozen_string_literal: true

class ConferencePaperEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ConferencePaperType)
end
