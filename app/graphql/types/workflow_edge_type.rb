# frozen_string_literal: true

class Types::WorkflowEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::WorkflowType)
end
