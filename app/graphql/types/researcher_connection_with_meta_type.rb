# frozen_string_literal: true

class ResearcherConnectionWithMetaType < BaseConnection
  edge_type(ResearcherEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Researcher.query(args[:query], page: { number: 1, size: 0 }).results.total
  end
end
