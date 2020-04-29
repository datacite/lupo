# frozen_string_literal: true

module Types
  class PrefixConnectionType < Types::BaseConnection
    edge_type(Types::PrefixEdgeType)
    field_class GraphQL::Cache::Field
    
    field :total_count, Integer, null: false, cache: true
    field :states, [Types::FacetType], null: false, cache: true
    field :years, [Types::FacetType], null: false, cache: true

    def total_count
      args = prepare_args(object.arguments)

      response(args).results.total
    end

    def states
      args = prepare_args(object.arguments)

      res = response(args)
      res.results.total.positive? ? facet_by_key(res.response.aggregations.states.buckets) : []
    end

    def years
      args = prepare_args(object.arguments)

      res = response(args)
      res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : []
    end

    def response(**args)
      Prefix.query(args[:query], provider_id: args[:member_id], state: args[:state], year: args[:year], page: { number: 1, size: 0 })
    end
  end
end
