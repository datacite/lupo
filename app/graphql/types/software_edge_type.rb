# frozen_string_literal: true

class Types::SoftwareEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::SoftwareType)
end
