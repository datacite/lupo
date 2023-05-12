# frozen_string_literal: true

class DissertationConnectionWithTotalType < BaseConnection
  edge_type(DissertationEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
