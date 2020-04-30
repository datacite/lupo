# frozen_string_literal: true

class JournalArticleEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(JournalArticleType)
end
