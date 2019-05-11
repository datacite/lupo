# frozen_string_literal: true

class PrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PrefixType)
end
