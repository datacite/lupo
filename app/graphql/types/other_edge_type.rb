# frozen_string_literal: true

class OtherEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(OtherType)
end
