# frozen_string_literal: true

class PhysicalObjectConnectionWithTotalType < BaseConnection
  edge_type(PhysicalObjectEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
