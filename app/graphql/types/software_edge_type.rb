# frozen_string_literal: true

class SoftwareEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(SoftwareType)
end
