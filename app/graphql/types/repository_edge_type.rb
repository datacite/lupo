# frozen_string_literal: true

class RepositoryEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(RepositoryType)
end
