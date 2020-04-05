# frozen_string_literal: true

class WorkflowEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(WorkflowType)
end
