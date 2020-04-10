# frozen_string_literal: true

class MemberPrefixConnectionType < BaseConnection
  edge_type(MemberPrefixEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :states, [FacetType], null: false, cache: true
  field :years, [FacetType], null: false, cache: true

  def total_count
    args = object.arguments
    args[:member_id] ||= object.parent.try(:role_name).present? ? object.parent.symbol.downcase : nil

    response(**args).results.total
  end

  def states
    args = object.arguments
    args[:member_id] ||= object.parent.try(:role_name).present? ? object.parent.symbol.downcase : nil

    res = response(**args)
    res.results.total.positive? ? facet_by_key(res.response.aggregations.states.buckets) : nil
  end

  def years
    args = object.arguments
    args[:member_id] ||= object.parent.try(:role_name).present? ? object.parent.symbol.downcase : nil

    res = response(**args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : nil
  end

  def response(**args)
    @response ||= ProviderPrefix.query(args[:query], provider_id: args[:member_id], state: args[:state], year: args[:year], page: { number: 1, size: 0 })
  end
end
