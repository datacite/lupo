# frozen_string_literal: true

class PhysicalObjectEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PhysicalObjectType)
end
