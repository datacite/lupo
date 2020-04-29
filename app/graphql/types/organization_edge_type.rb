# frozen_string_literal: true

module Types
  class OrganizationEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::OrganizationType)
  end
end
