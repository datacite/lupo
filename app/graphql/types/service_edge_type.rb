# frozen_string_literal: true

class Types::ServiceEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::ServiceType)
end
