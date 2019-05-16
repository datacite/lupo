# frozen_string_literal: true

class ClientConnectionWithMetaType < BaseConnection
  edge_type(ClientEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    object.nodes.size
  end
end
