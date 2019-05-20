# frozen_string_literal: true

class PrefixConnectionWithMetaType < BaseConnection
  edge_type(PrefixEdgeType)
  field_class GraphQL::Cache::Field
  
  field :total_count, Integer, null: false, cache: true
  field :states, [FacetType], null: false, cache: true
  field :years, [FacetType], null: false, cache: true

  def total_count
    object.nodes.size
  end

  def states
    args = self.object.arguments

    if object.parent._index == "providers"
      collection = ProviderPrefix.joins(:provider, :prefix).where('allocator.symbol = ?', object.parent.symbol) 
      collection = collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]) if args[:year].present?
      collection = collection.state(args[:state].underscore.dasherize) if args[:state].present?
      collection = collection.query(args[:query]) if args[:query].present?
      
      puts collection.inspect
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

    if object.parent._index == "providers"
      collection = ProviderPrefix.joins(:provider, :prefix).where('allocator.symbol = ?', object.parent.symbol) 
      collection = collection.state(args[:state].underscore.dasherize) if args[:state].present?
      collection = collection.query(args[:query]) if args[:query].present?

      if args[:year].present?
        [{ id: args[:year],
           title: args[:year],
           count: collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]).count }]
      else
        years = collection.where.not(prefixes: nil).order("YEAR(allocator_prefixes.created_at) DESC").group("YEAR(allocator_prefixes.created_at)").count
        years.map { |k,v| { id: k.to_s, title: k.to_s, count: v } }
      end
    elsif object.parent._index == "clients"
      collection = ClientPrefix.joins(:client, :prefix).where('datacentre.symbol = ?', object.parent.symbol)
      collection = collection.query(args[:query]) if args[:query].present?
      
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
