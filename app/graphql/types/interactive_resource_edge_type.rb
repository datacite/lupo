# frozen_string_literal: true

class Types::InteractiveResourceEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::InteractiveResourceType)
end
