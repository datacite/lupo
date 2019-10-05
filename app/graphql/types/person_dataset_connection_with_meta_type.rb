# frozen_string_literal: true

class PersonDatasetConnectionWithMetaType < BaseConnection
  edge_type(EventDataEdgeType, edge_class: EventDataEdge)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true

  def total_count
    Event.query(nil, obj_id: https_to_http(object.parent[:id] ? "https://orcid.org/#{object.parent[:id]}" : nil || object.parent[:id]), citation_type: "Dataset-Person").results.total
  end

  def https_to_http(url)
    uri = Addressable::URI.parse(url)
    uri.scheme = "http" if uri.present?
    uri.to_s
  end
end