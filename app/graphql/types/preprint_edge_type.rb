# frozen_string_literal: true

class PreprintEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PreprintType)
end
