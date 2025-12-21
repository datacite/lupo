# frozen_string_literal: true

class WorkflowConnectionWithTotalType < BaseConnection
  edge_type(WorkflowEdgeType)
  implements Interfaces::WorkFacetsInterface
end
