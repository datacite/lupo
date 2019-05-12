# frozen_string_literal: true

class ProviderEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ProviderType)
end
