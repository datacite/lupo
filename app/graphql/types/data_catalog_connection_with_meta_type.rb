# frozen_string_literal: true

class DataCatalogConnectionWithMetaType < BaseConnection
  edge_type(DataCatalogEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: true, cache: true

  def total_count
    args = object.arguments
    DataCatalog.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
