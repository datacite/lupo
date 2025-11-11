# frozen_string_literal: true

class PrefixConnectionWithTotalType < BaseConnection
  edge_type(PrefixEdgeType)

  field :total_count, Integer, null: false, cache_fragment: true
  field :states, [FacetType], null: false, cache_fragment: true
  field :years, [FacetType], null: false, cache_fragment: true

  def total_count
    object.total_count
  end

  def states
    facet_by_key(object.aggregations.states.buckets)
  end

  def years
    facet_by_year(object.aggregations.years.buckets)
  end
end
