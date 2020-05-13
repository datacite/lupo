# frozen_string_literal: true

class ActorConnectionType < BaseConnection
  edge_type(ActorEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  
  def total_count
    args = object.arguments

    Organization.query(args[:query], limit: 0).dig(:meta, "total").to_i + 
    Funder.query(args[:query], limit: 0).dig(:meta, "total").to_i +
    Person.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
