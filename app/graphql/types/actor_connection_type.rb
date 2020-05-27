# frozen_string_literal: true

class ActorConnectionType < BaseConnection
  edge_type(ActorEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  
  def total_count
    object.total_count 
  end
end
