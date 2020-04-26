# frozen_string_literal: true

class Types::RepositoryConnectionType < Types::BaseConnection
  edge_type(Types::RepositoryEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: true, cache: true
  field :years, [Types::FacetType], null: true, cache: true
  field :software, [Types::FacetType], null: true, cache: true

  def total_count
    args = prepare_args(object.arguments)

    response(args).results.total  
  end

  def years
    args = prepare_args(object.arguments)

    r = response(args)
    r.results.total.positive? ? facet_by_year(r.response.aggregations.years.buckets) : nil
  end

  def software
    args = prepare_args(object.arguments)

    r = response(args)
    r.results.total.positive? ? facet_by_software(r.response.aggregations.software.buckets) : nil
  end

  def response(**args)
    Client.query(args[:query], provider_id: args[:member_id], year: args[:year], software: args[:software], page: { number: 1, size: 0 })
  end
end
