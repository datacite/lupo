# frozen_string_literal: true

class MemberPrefixConnectionWithTotalType < BaseConnection
  edge_type(MemberPrefixEdgeType)

  field :total_count, Integer, null: false
  field :states, [FacetType], null: false
  field :years, [FacetType], null: false

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
