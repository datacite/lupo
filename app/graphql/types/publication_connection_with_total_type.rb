# frozen_string_literal: true

class PublicationConnectionWithTotalType < BaseConnection
  edge_type(PublicationEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface

  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :person_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true


  def publication_connection_count
    @publication_connection_count ||=
      Event.query(
        nil,
        citation_type: "ScholarlyArticle-ScholarlyArticle",
        page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def dataset_connection_count
    @dataset_connection_count ||=
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
        citation_type: "ScholarlyArticle-SoftwareSourceCode",
        page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def person_connection_count
    @person_connection_count ||=
      Event.query(
        nil,
        citation_type: "Person-ScholarlyArticle", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def funder_connection_count
    @funder_connection_count ||=
      Event.query(
        nil,
        citation_type: "Funder-ScholarlyArticle", page: { number: 1, size: 0 },
      ).
        results.
        total
  end

  def organization_connection_count
    @organization_connection_count ||=
      Event.query(
        nil,
        citation_type: "Organization-ScholarlyArticle",
        page: { number: 1, size: 0 },
      ).
        results.
        total
  end
end
