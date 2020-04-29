# frozen_string_literal: true

module Types
  class OtherEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::OtherType)
  end
end
