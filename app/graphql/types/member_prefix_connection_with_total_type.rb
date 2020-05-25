# frozen_string_literal: true

class MemberPrefixConnectionWithTotalType < BaseConnection
  edge_type(MemberPrefixEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :states, [FacetType], null: false, cache: true
  field :years, [FacetType], null: false, cache: true

  def total_count
    object.total_count
  end

  def states
    object.total_count.positive? ? facet_by_key(object.aggregations.states.buckets) : []
  end

  def years
    object.total_count.positive? ? facet_by_year(object.aggregations.years.buckets) : []
  end
end
