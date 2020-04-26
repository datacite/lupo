# frozen_string_literal: true

class Types::BookChapterEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(BookChapterType)
end
