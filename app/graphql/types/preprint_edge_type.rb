# frozen_string_literal: true

class Types::PreprintEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PreprintType)
end
