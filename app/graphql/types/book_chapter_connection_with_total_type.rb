# frozen_string_literal: true

class BookChapterConnectionWithTotalType < BaseConnection
  edge_type(BookChapterEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :published, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :licenses, [FacetType], null: true, cache: true

  def total_count
    object.total_count  
  end

  def published
    object.total_count.positive? ? facet_by_range(object.aggregations.published.buckets) : []
  end

  def registration_agencies
    object.total_count.positive? ? facet_by_registration_agency(object.aggregations.registration_agencies.buckets) : []
  end

  def repositories
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.clients.buckets) : []
  end

  def affiliations
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.affiliations.buckets) : []
  end

  def licenses
    object.total_count.positive? ? facet_by_software(object.aggregations.licenses.buckets) : []
  end
end
