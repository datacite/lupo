# frozen_string_literal: true

class SoftwareConnectionWithTotalType < BaseConnection
  edge_type(SoftwareEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true  
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :fields_of_science, [FacetType], null: true, cache: true

  field :software_connection_count, Integer, null: false, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :person_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true

  def total_count
    object.total_count
  end

  def years
    object.total_count.positive? ? facet_by_year(object.aggregations.years.buckets) : []
  end

  def registration_agencies
    object.total_count.positive? ? facet_by_software(object.aggregations.registration_agencies.buckets) : []
  end

  def repositories
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.clients.buckets) : []
  end

  def affiliations
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.affiliations.buckets) : []
  end

  def software_connection_count
    Event.query(nil, citation_type: "SoftwareSourceCode-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def publication_connection_count
    Event.query(nil, citation_type: "ScholarlyArticle-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def dataset_connection_count
    Event.query(nil, citation_type: "Dataset-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def person_connection_count
    Event.query(nil, citation_type: "Person-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def funder_connection_count
    Event.query(nil, citation_type: "Funder-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def organization_connection_count
    Event.query(nil, citation_type: "Organization-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def fields_of_science
    object.total_count.positive? ? facet_by_combined_key(object.aggregations.fields_of_science.subject.buckets) : []
  end
end
