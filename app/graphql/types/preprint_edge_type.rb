# frozen_string_literal: true

module Types
  class PreprintEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PreprintType)
  end
end
