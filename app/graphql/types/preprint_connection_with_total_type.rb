# frozen_string_literal: true

class PreprintConnectionWithTotalType < BaseConnection
  edge_type(PreprintEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
