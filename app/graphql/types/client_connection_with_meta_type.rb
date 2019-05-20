# frozen_string_literal: true

class ClientConnectionWithMetaType < BaseConnection
  edge_type(ClientEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Client.query(args[:query], year: args[:year], software: args[:software], page: { number: 1, size: 0 }).results.total
  end
end
