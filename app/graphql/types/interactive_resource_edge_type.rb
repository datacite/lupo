# frozen_string_literal: true

class InteractiveResourceEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(InteractiveResourceType)
end
