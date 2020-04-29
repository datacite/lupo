# frozen_string_literal: true

module Types
  class PrefixEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PrefixType)
  end
end
