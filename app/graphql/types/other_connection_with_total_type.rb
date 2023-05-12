# frozen_string_literal: true

class OtherConnectionWithTotalType < BaseConnection
  edge_type(OtherEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
