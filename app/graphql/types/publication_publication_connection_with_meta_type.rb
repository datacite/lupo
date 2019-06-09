# frozen_string_literal: true

class PublicationPublicationConnectionWithMetaType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    Event.query(nil, doi_id: doi_from_url(object.parent.identifier), citation_type: "ScholarlyArticle-ScholarlyArticle").results.total
  end
end
