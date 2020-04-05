# frozen_string_literal: true

class CollectionEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(CollectionType)
end
