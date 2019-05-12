# frozen_string_literal: true

class ClientEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ClientType)
end
