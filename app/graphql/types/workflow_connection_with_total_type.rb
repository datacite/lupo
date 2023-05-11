# frozen_string_literal: true

class WorkflowConnectionWithTotalType < BaseConnection
  edge_type(WorkflowEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
