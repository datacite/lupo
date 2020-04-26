# frozen_string_literal: true

class Types::RepositoryPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::RepositoryPrefixType)
end
