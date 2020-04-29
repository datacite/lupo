# frozen_string_literal: true

module Types
  class RepositoryPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::RepositoryPrefixType)
  end
end
