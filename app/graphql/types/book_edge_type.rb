# frozen_string_literal: true

class BookEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(BookType)
end
