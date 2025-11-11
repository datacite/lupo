# frozen_string_literal: true

class DatasetConnectionWithTotalType < BaseConnection
  edge_type(DatasetEdgeType)
  implements Interfaces::WorkFacetsInterface


  field :dataset_connection_count, Integer, null: false, cache_fragment: true
  field :publication_connection_count, Integer, null: false, cache_fragment: true
  field :software_connection_count, Integer, null: false, cache_fragment: true
  field :person_connection_count, Integer, null: false, cache_fragment: true
  field :funder_connection_count, Integer, null: false, cache_fragment: true
  field :organization_connection_count, Integer, null: false, cache_fragment: true

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
