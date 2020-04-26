# frozen_string_literal: true

class Types::OtherEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::OtherType)
end
