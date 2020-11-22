# frozen_string_literal: true

class DatasetConnectionWithTotalType < BaseConnection
  edge_type(DatasetEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :published, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true
  field :fields_of_science, [FacetType], null: true, cache: true
  field :licenses, [FacetType], null: true, cache: true
  field :languages, [FacetType], null: true, cache: true

  field :dataset_connection_count, Integer, null: false, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :person_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true

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

  def fields_of_science
    facet_by_fos(object.aggregations.fields_of_science.subject.buckets)
  end

  def languages
    facet_by_language(object.aggregations.languages.buckets)
  end

  def dataset_connection_count
    @dataset_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-Dataset", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def publication_connection_count
    @publication_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-ScholarlyArticle", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def software_connection_count
    @software_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-SoftwareSourceCode",
        page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def person_connection_count
    @person_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-Person", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def funder_connection_count
    @funder_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-Funder", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def organization_connection_count
    @organization_connection_count ||=
      Event.query(
        nil,
        citation_type: "Dataset-Organization", page: { number: 1, size: 0 },
      ).
        results.
        total
  end
end
