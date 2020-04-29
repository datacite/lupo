# frozen_string_literal: true

module Types
  class PhysicalObjectEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PhysicalObjectType)
  end
end
