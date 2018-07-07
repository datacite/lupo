module Facetable
  extend ActiveSupport::Concern

  included do
    def client_year_facet(params, collection)
      [{ id: params[:year],
         title: params[:year],
         count: collection.where('YEAR(datacentre.created) = ?', params[:year]).count }]
    end

    def facet_by_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_key(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].humanize,
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_schema(arr)
      arr.map do |hsh|
        id = hsh["key"].split("-").last

        { "id" => id,
          "title" => "Schema #{id}",
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_provider(arr)
      # generate hash with id and name for each provider in facet
      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_ids(ids).results.reduce({}) do |sum, p|
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"]],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_provider_ids(arr)
      # generate hash with id and name for each provider in facet
      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_id_list(ids).results.reduce({}) do |sum, p|
        sum[p.id] = p.name
        sum
      end

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"]],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_client(arr)
      # generate hash with id and name for each client in facet
      ids = arr.map { |hsh| hsh["key"] }.join(",")
      clients = Client.find_by_ids(ids).results.reduce({}) do |sum, p|
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => clients[hsh["key"]],
          "count" => hsh["doc_count"] }
      end
    end
  end
end

