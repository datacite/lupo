# frozen_string_literal: true

class DataManagementPlanConnectionWithTotalType < BaseConnection
  edge_type(DataManagementPlanEdgeType)
  implements Interfaces::WorkFacetsInterface
end
