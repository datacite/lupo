# frozen_string_literal: true

class RepositoryConnectionWithMetaType < BaseConnection
  edge_type(RepositoryEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Repository.query(args[:query], open: args[:open], pid: args[:pid], certified: args[:certified], subject: args[:subject], software: args[:software], disciplinary: args[:disciplinary], limit: 0).dig(:meta, "total").to_i
  end
end
