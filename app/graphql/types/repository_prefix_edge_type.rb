# frozen_string_literal: true

class RepositoryPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(RepositoryPrefixType)
end
