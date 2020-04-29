# frozen_string_literal: true

module Types
  class BookChapterEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(BookChapterType)
  end
end
