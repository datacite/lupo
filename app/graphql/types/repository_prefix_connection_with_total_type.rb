# frozen_string_literal: true

class RepositoryPrefixConnectionWithTotalType < BaseConnection
  edge_type(RepositoryPrefixEdgeType)

  field :total_count, Integer, null: false
  field :years, [FacetType], null: false

  def total_count
    object.total_count
  end

  def years
    facet_by_year(object.aggregations.years.buckets)
  end
end
