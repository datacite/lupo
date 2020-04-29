# frozen_string_literal: true

module Types
  class InteractiveResourceEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::InteractiveResourceType)
  end
end
