# frozen_string_literal: true

module Types
  class CollectionEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::CollectionType)
  end
end
