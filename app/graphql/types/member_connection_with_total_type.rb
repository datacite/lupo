# frozen_string_literal: true

class MemberConnectionWithTotalType < BaseConnection
  edge_type(MemberEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :regions, [FacetType], null: true, cache: true
  field :member_types, [FacetType], null: true, cache: true
  field :organization_types, [FacetType], null: true, cache: true
  field :focus_areas, [FacetType], null: true, cache: true
  field :non_profit_statuses, [FacetType], null: true, cache: true

  def total_count
    object.total_count
  end

  def years
    object.total_count.positive? ? facet_by_year(object.aggregations.years.buckets) : nil
  end

  def regions
    object.total_count.positive? ? facet_by_region(object.aggregations.regions.buckets) : nil
  end

  def member_types
    object.total_count.positive? ? facet_by_key(object.aggregations.member_types.buckets) : nil
  end

  def organization_types
    object.total_count.positive? ? facet_by_key(object.aggregations.organization_types.buckets) : nil
  end

  def focus_areas
    object.total_count.positive? ? facet_by_key(object.aggregations.focus_areas.buckets) : nil
  end

  def non_profit_statuses
    object.total_count.positive? ? facet_by_key(object.aggregations.non_profit_statuses.buckets) : nil
  end
end
