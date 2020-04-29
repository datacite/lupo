# frozen_string_literal: true

module Types
  class RepositoryEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::RepositoryType)
  end
end
