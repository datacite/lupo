# frozen_string_literal: true

class OrganizationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(OrganizationType)
end
