# frozen_string_literal: true

class ModelConnectionWithTotalType < BaseConnection
  edge_type(ModelEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
