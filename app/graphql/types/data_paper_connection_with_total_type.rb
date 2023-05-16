# frozen_string_literal: true

class DataPaperConnectionWithTotalType < BaseConnection
  edge_type(DataPaperEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
