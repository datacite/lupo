# frozen_string_literal: true

class ServiceEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ServiceType)
end
