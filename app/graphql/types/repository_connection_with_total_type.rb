# frozen_string_literal: true

class RepositoryConnectionWithTotalType < BaseConnection
  edge_type(RepositoryEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: true, cache: true
  field :software, [FacetType], null: true, cache: true
  field :certificates, [FacetType], null: true, cache: true
  field :repository_types, [FacetType], null: true, cache: true
  field :years, [FacetType], null: true, cache: true
  field :members, [FacetType], null: true, cache: true

  def total_count
    object.total_count
  end

  def years
    facet_by_year(object.aggregations.years.buckets)
  end

  def software
    facet_by_software(object.aggregations.software.buckets)
  end

  def repository_types
    facet_by_key(object.aggregations.repository_types.buckets)
  end

  def certificates
    facet_by_key_raw(object.aggregations.certificates.buckets)
  end

  def members
    facet_by_combined_key(object.aggregations.providers.buckets)
  end
end
