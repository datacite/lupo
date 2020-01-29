# frozen_string_literal: true

class ProviderClientConnectionWithMetaType < BaseConnection
  edge_type(ClientEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Client.query(args[:query], provider_id: object.parent.uid, year: args[:year], software: args[:software], page: { number: 1, size: 0 }).results.total
  end
end
