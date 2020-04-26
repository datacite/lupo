# frozen_string_literal: true

class Types::DataCatalogConnectionType < Types::BaseConnection
  edge_type(Types::DataCatalogEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: true, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments
    
    DataCatalog.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end

  def dataset_connection_count
    @dataset_connection_count ||= Doi.query("client.re3data_id:*", page: { number: 1, size: 0 }).results.total
  end
end
