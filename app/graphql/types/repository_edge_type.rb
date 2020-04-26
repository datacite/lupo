# frozen_string_literal: true

class Types::RepositoryEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::RepositoryType)
end
