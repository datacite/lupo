# frozen_string_literal: true

class RepositoryConnectionWithMetaType < BaseConnection
  edge_type(RepositoryEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Repository.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
