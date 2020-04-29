# frozen_string_literal: true

module Types
  class WorkflowEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::WorkflowType)
  end
end
