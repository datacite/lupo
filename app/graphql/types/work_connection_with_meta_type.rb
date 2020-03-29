# frozen_string_literal: true

class WorkConnectionWithMetaType < BaseConnection
  edge_type(WorkEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :resource_types, [FacetType], null: true, cache: true

  def total_count
    args = prepare_args(object.arguments)

    response(**args).results.total  
  end

  def years
    args = prepare_args(object.arguments)
    
    res = response(**args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : nil
  end

  def resource_types
    args = prepare_args(object.arguments)

    res = response(**args)
    res.results.total.positive? ? facet_by_resource_type(res.response.aggregations.resource_types.buckets) : nil
  end

  def response(**args)
    @response ||= Doi.query(args[:query], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], year: args[:year], resource_type_id: args[:resource_type_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], page: { number: 1, size: 0 })
  end
end
