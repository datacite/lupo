# frozen_string_literal: true

class Types::PrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PrefixType)
end
