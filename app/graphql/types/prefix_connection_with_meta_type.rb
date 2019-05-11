# frozen_string_literal: true

class PrefixConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(PrefixEdgeType)

  field :total_count, Integer, null: false
  field :states, [FacetType], null: false
  field :years, [FacetType], null: false

  def total_count
    object.nodes.size
  end

  def states
    args = self.object.arguments

    if object.parent.class.name == "Provider"
      collection = object.parent.provider_prefixes.joins(:prefix)
      collection = collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]) if args[:year].present?

      if args[:state].present?
        [{ id: args[:state],
           title: args[:state].underscore.humanize,
           count: collection.state(args[:state].underscore.dasherize).count }]
      else
        [{ id: "withoutClient",
           title: "Without client",
           count: collection.state("without-client").count },
         { id: "withClient",
           title: "With client",
           count: collection.state("with-client").count }]
      end
    else
      []
    end
  end

  def years
    args = self.object.arguments

    if object.parent.class.name == "Provider"
      collection = object.parent.provider_prefixes.joins(:prefix)
      collection = collection.state(args[:state].underscore.dasherize) if args[:state].present?
      
      if args[:year].present?
        [{ id: args[:year],
           title: args[:year],
           count: collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]).count }]
      else
        years = collection.where.not(prefixes: nil).order("YEAR(allocator_prefixes.created_at) DESC").group("YEAR(allocator_prefixes.created_at)").count
        years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
      end
    elsif object.parent.class.name == "Client"
      collection = object.parent.client_prefixes.joins(:prefix)

      if args[:year].present?
        [{ id: args[:year],
           title: args[:year],
           count: collection.where('YEAR(datacentre_prefixes.created_at) = ?', args[:year]).count }]
      else
        years = collection.where.not(prefixes: nil).order("YEAR(datacentre_prefixes.created_at) DESC").group("YEAR(datacentre_prefixes.created_at)").count
        years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
      end
    else
      {}
    end
  end
end
