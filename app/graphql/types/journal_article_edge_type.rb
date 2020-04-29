# frozen_string_literal: true

module Types
  class JournalArticleEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::JournalArticleType)
  end
end
