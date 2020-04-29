# frozen_string_literal: true

module Types
  class ServiceEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::ServiceType)
  end
end
