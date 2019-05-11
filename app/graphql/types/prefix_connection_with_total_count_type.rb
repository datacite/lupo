# frozen_string_literal: true

class PrefixConnectionWithTotalCountType < GraphQL::Types::Relay::BaseConnection
  edge_type(PrefixEdgeType)

  field :total_count, Integer, null: false
  field :years, [FacetType], null: false

  def total_count
    object.nodes.size
  end

  def years
    if object.parent.class.name == "Provider"
      collection = object.parent.provider_prefixes.joins(:prefix)
      years = collection.where.not(prefixes: nil).order("YEAR(allocator_prefixes.created_at) DESC").group("YEAR(allocator_prefixes.created_at)").count
      years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    elsif object.parent.class.name == "Client"
      collection = object.parent.client_prefixes.joins(:prefix)
      years = collection.where.not(prefixes: nil).order("YEAR(datacentre_prefixes.created_at) DESC").group("YEAR(datacentre_prefixes.created_at)").count
      years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
    else
      {}
    end
  end
end
