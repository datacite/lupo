# frozen_string_literal: true

class InteractiveResourceConnectionWithTotalType < BaseConnection
  edge_type(InteractiveResourceEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
