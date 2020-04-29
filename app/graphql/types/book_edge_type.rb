# frozen_string_literal: true

module Types
  class BookEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::BookType)
  end
end
