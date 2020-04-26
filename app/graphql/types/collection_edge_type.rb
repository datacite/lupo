# frozen_string_literal: true

class Types::CollectionEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::CollectionType)
end
