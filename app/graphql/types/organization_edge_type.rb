# frozen_string_literal: true

class Types::OrganizationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::OrganizationType)
end
