# frozen_string_literal: true

class ReferenceRepositoryConnectionWithTotalType < BaseConnection
  edge_type(ReferenceRepositoryEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: true, cache: true
  def total_count
    object.total_count
  end
end
