# frozen_string_literal: true

class OrganizationConnectionWithTotalType < BaseConnection
  edge_type(OrganizationEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :types, [FacetType], null: true, cache: true
  field :countries, [FacetType], null: true, cache: true
  field :person_connection_count, Integer, null: false, cache: true

  def total_count
    object.total_count
  end

  def types
    object.meta["types"]
  end

  def countries
    object.meta["countries"]
  end

  def person_connection_count
    @person_connection_count ||= Event.query(nil, citation_type: "Organization-Person").results.total
  end
end
