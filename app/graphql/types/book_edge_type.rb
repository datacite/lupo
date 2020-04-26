# frozen_string_literal: true

class Types::BookEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::BookType)
end
