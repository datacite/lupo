# frozen_string_literal: true

class ResearcherConnectionWithMetaType < BaseConnection
  edge_type(ResearcherEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  
  def total_count
    args = object.arguments

    Researcher.query(args[:query], page: { number: 1, size: 0 }).results.total
  end

  def publication_connection_count
    Event.query(nil, citation_type: "Researcher-ScholarlyArticle").results.total
  end

  def dataset_connection_count
    Event.query(nil, citation_type: "Dataset-Researcher").results.total
  end

  def software_connection_count
    Event.query(nil, citation_type: "Researcher-SoftwareSourceCode").results.total
  end
end
