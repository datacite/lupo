# frozen_string_literal: true

class SoftwareSoftwareConnectionWithMetaType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    Event.query(nil, doi: doi_from_url(object.parent.identifier), citation_type: "SoftwareSourceCode-SoftwareSourceCode").results.total
  end
end
