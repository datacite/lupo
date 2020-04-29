# frozen_string_literal: true

module Types
  class SoftwareEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::SoftwareType)
  end
end
