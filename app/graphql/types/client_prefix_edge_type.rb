# frozen_string_literal: true

class ClientPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ClientPrefixType)
end
