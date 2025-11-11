# frozen_string_literal: true

class ActorConnectionType < BaseConnection
  edge_type(ActorEdgeType)

  field :total_count, Integer, null: false, cache_fragment: true

  def total_count
    object.total_count
  end
end
