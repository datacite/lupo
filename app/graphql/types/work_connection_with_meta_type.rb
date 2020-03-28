# frozen_string_literal: true

class WorkConnectionWithMetaType < BaseConnection
  edge_type(WorkEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Doi.query(args[:query], client_id: args[:client_id], provider_id: args[:provider_id], state: "findable", page: { number: 1, size: 0 }).results.total
  end
end
