# frozen_string_literal: true

class CollectionConnectionWithTotalType < BaseConnection
  edge_type(CollectionEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :published, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :licenses, [FacetType], null: true, cache: true
  field :languages, [FacetType], null: true, cache: true

  def total_count
    object.total_count
  end

  def published
    facet_by_range(object.aggregations.published.buckets)
  end

  def registration_agencies
    facet_by_registration_agency(
      object.aggregations.registration_agencies.buckets,
    )
  end

  def repositories
    facet_by_combined_key(object.aggregations.clients.buckets)
  end

  def affiliations
    facet_by_combined_key(object.aggregations.affiliations.buckets)
  end

  def licenses
    facet_by_license(object.aggregations.licenses.buckets)
  end

  def languages
    facet_by_language(object.aggregations.languages.buckets)
  end
end
