# frozen_string_literal: true

class SoftwareConnectionWithMetaType < BaseConnection
  edge_type(DatasetEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :person_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Doi.query(args[:query], client_id: args[:client_id], provider_id: args[:provider_id], resource_type_id: "Software", state: "findable", page: { number: 1, size: 0 }).results.total
  end

  def software_connection_count
    Event.query(nil, citation_type: "SoftwareSourceCode-SoftwareSourceCode").results.total
  end

  def publication_connection_count
    Event.query(nil, citation_type: "ScholarlyArticle-SoftwareSourceCode").results.total
  end

  def dataset_connection_count
    Event.query(nil, citation_type: "Dataset-SoftwareSourceCode").results.total
  end

  def person_connection_count
    Event.query(nil, citation_type: "Person-SoftwareSourceCode").results.total
  end

  def funder_connection_count
    Event.query(nil, citation_type: "Funder-SoftwareSourceCode").results.total
  end

  def organization_connection_count
    Event.query(nil, citation_type: "Organization-SoftwareSourceCode").results.total
  end
end
