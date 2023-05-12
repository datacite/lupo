# frozen_string_literal: true

class ConferencePaperConnectionWithTotalType < BaseConnection
  edge_type(ConferencePaperEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
