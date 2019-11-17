# frozen_string_literal: true

class DoiConnectionWithMetaType < BaseConnection
  edge_type(DatasetEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Doi.query(args[:query], state: "findable", page: { number: 1, size: args[:first] }).results.total
  end
end
