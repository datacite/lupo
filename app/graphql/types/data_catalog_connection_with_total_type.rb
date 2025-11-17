# frozen_string_literal: true

class DataCatalogConnectionWithTotalType < BaseConnection
  edge_type(DataCatalogEdgeType)

  field :total_count, Integer, null: true
  field :dataset_connection_count, Integer, null: false

  def total_count
    object.total_count
  end

  def dataset_connection_count
    @dataset_connection_count ||=
      Doi.gql_query("client.re3data_id:*", page: { number: 1, size: 0 }).results.
        total
  end
end
