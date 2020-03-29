# frozen_string_literal: true

class ClientConnectionWithMetaType < BaseConnection
  edge_type(ClientEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: true, cache: true
  field :years, [FacetType], null: true, cache: true
  field :software, [FacetType], null: true, cache: true

  def total_count
    args = prepare_args(object.arguments)

    response(**args).results.total  
  end

  def years
    args = prepare_args(object.arguments)

    res = response(**args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : nil
  end

  def software
    args = prepare_args(object.arguments)

    res = response(**args)
    res.results.total.positive? ? facet_by_software(res.response.aggregations.software.buckets) : nil
  end

  def response(**args)
    @response ||= Client.query(args[:query], provider_id: args[:provider_id], year: args[:year], software: args[:software], page: { number: 1, size: 0 })
  end
end
