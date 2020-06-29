# frozen_string_literal: true

class OtherConnectionWithTotalType < BaseConnection
  edge_type(OtherEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :languages, [FacetType], null: true, cache: true

  def total_count
    object.total_count 
  end

  def years
    object.total_count.positive? ? facet_by_range(object.aggregations.years.buckets) : []
  end

  def registration_agencies
    object.total_count.positive? ? facet_by_registration_agency(object_id.aggregations.registration_agencies.buckets) : []
  end

  def repositories
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.clients.buckets) : []
  end

  def affiliations
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.affiliations.buckets) : []
  end

  def languages
    object.total_count.positive? ? facet_by_language(object.aggregations.languages.buckets) : []
  end
end
