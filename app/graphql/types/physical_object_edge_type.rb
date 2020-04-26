# frozen_string_literal: true

class Types::PhysicalObjectEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PhysicalObjectType)
end
