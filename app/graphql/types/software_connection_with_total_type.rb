# frozen_string_literal: true

class SoftwareConnectionWithTotalType < BaseConnection
  edge_type(SoftwareEdgeType)
  implements Interfaces::WorkFacetsInterface

  field :dataset_connection_count, Integer, null: false
  field :funder_connection_count, Integer, null: false
  field :organization_connection_count, Integer, null: false
  field :person_connection_count, Integer, null: false
  field :publication_connection_count, Integer, null: false
  field :software_connection_count, Integer, null: false

  def dataset_connection_count
    Event.query(
      nil,
      citation_type: "Dataset-SoftwareSourceCode", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def funder_connection_count
    Event.query(
      nil,
      citation_type: "Funder-SoftwareSourceCode", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def organization_connection_count
    Event.query(
      nil,
      citation_type: "Organization-SoftwareSourceCode",
      page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def software_connection_count
    Event.query(
      nil,
      citation_type: "SoftwareSourceCode-SoftwareSourceCode",
      page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def person_connection_count
    Event.query(
      nil,
      citation_type: "Person-SoftwareSourceCode", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def publication_connection_count
    Event.query(
      nil,
      citation_type: "ScholarlyArticle-SoftwareSourceCode",
      page: { number: 1, size: 0 },
    ).
      results.
      total
  end
end
