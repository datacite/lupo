# frozen_string_literal: true

class Types::JournalArticleEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::JournalArticleType)
end
