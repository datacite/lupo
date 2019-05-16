# frozen_string_literal: true

class FunderConnectionWithMetaType < BaseConnection
  edge_type(FunderEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Funder.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
