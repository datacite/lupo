# frozen_string_literal: true

class RepositoryPrefixConnectionType < BaseConnection
  edge_type(RepositoryPrefixEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: false, cache: true

  def total_count
    args = prepare_args(object.arguments)

    response(**args).results.total
  end

  def years
    args = prepare_args(object.arguments)
    
    res = response(**args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : nil
  end

  def response(**args)
    @response ||= ClientPrefix.query(args[:query], client_id: args[:repository_id], provider_id: args[:member_id], state: args[:state], year: args[:year], page: { number: 1, size: 0 })
  end
end
