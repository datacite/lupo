# frozen_string_literal: true

class DataManagementPlanConnectionWithTotalType < BaseConnection
  edge_type(DataManagementPlanEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
