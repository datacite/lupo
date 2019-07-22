# frozen_string_literal: true

class OrganizationConnectionWithMetaType < BaseConnection
  edge_type(OrganizationEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :researcher_connection_count, Integer, null: false, cache: true

  def total_count
    args = object.arguments

    Organization.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end

  def researcher_connection_count
    Event.query(nil, citation_type: "Organization-Person").results.total
  end
end
