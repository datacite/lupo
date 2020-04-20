# frozen_string_literal: true

class MemberConnectionType < BaseConnection
  edge_type(MemberEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Provider.query(args[:query], year: args[:year], page: { number: 1, size: 0 }).results.total
  end
end
