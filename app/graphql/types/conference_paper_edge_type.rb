# frozen_string_literal: true

class Types::ConferencePaperEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::ConferencePaperType)
end
