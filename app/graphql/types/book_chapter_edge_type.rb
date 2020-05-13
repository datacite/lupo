# frozen_string_literal: true

class BookChapterEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(BookChapterType)
end
