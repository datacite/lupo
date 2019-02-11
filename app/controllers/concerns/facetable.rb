module Facetable
  extend ActiveSupport::Concern

  included do

    REGIONS = { 
      "amer" => "Americas",
      "apac" => "Asia Pacific",
      "emea" => "EMEA" }

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

    def facet_anual(arr)
      arr.map do |hsh|
        { "id" => hsh["key"][0..3],
          "title" => hsh["key"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_date(arr)
      arr.map do |hsh|
        { "id" => hsh["key"][0..9],
          "title" => hsh["key"][0..9],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_cumulative_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key"].to_s,
          "title" => hsh["key"].to_s,
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_key(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].titleize,
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_software(arr)
      arr.map do |hsh|
        { "id" => hsh["key"].downcase,
          "title" => hsh["key"],
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

    def facet_by_region(arr)
      arr.map do |hsh|
        hsh["key"] = hsh["key"].downcase

        { "id" => hsh["key"],
          "title" => REGIONS[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_resource_type(arr)
      arr.map do |hsh|
        { "id" => hsh["key"].underscore.dasherize,
          "title" => hsh["key"],
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

    def facet_by_providers_totals(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_ids(ids).results.reduce({}) do |sum, p|
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"]],
          "count" => hsh["doc_count"],
          "temporal" => {
          "this_month" => facet_anual(hsh.this_month.buckets),
          "this_year" => facet_anual(hsh.this_year.buckets),
          "last_year" => facet_anual(hsh.last_year.buckets)},
          "states"    => facet_by_key(hsh.states.buckets)
        }
      end
    end

    def facet_by_clients_totals(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| hsh["key"] }.join(",")
      clients = Client.find_by_ids(ids).results.reduce({}) do |sum, p|
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
        puts hsh
        { "id" => hsh["key"],
          "title" => clients[hsh["key"]],
          "count" => hsh["doc_count"],
          "temporal" => {
          "this_month" => facet_anual(hsh.this_month.buckets),
          "this_year" => facet_anual(hsh.this_year.buckets),
          "last_year" => facet_anual(hsh.last_year.buckets)},
          "states"    => facet_by_key(hsh.states.buckets)
        }
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

    def prefixes_totals params={}
      page = { size: 0, number: 1 }
  
      prefixes = params[:client_id] ? Client.where(symbol: params[:client_id]).first.prefix_ids : Prefix.query("")
  
      ttl = prefixes.map do |prefix|
        prefix = prefix.respond_to?("downcase") ? prefix : prefix.prefix
        response = Doi.query("", client_id: params[:client_id], prefix: prefix, state: params[:state] || "",page: page)
        total = response.results.total
        states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
        temporal ={}
        temporal[:this_month] = total > 0 ? facet_by_date(response.response.aggregations.this_month.buckets) : nil
        temporal[:this_year] = total > 0 ? facet_anual(response.response.aggregations.this_year.buckets) : nil
        temporal[:last_year] = total > 0 ? facet_anual(response.response.aggregations.last_year.buckets) : nil
        id = prefix
        {id: id, title: id, count: total, states: states, temporal: temporal}
      end
      ttl
    end

    def totals_formatter item, response, page
        total = response.results.total
        states = total > 0 ? facet_by_key(response.response.aggregations.states.buckets) : nil
        temporal ={}
        temporal[:this_month] = total > 0 ? facet_by_date(response.response.aggregations.this_month.buckets) : nil
        temporal[:this_year] = total > 0 ? facet_anual(response.response.aggregations.this_year.buckets) : nil
        temporal[:last_year] = total > 0 ? facet_anual(response.response.aggregations.last_year.buckets) : nil
        id = item.symbol
        {id: id, title: item.name, count: total, states: states, temporal: temporal}
    end

    def providers_totals response, params
      page = { size: 0, number: 1}
      page_prov = { size: 500, number: 1}

      ttl = Provider.query(nil, page: page_prov).map do |item| 
        response = Doi.query(nil, provider_id: item.symbol.downcase, state: params[:state] || "", page: page)     
        totals_formatter item, response, page
      end
      ttl
    end

    def clients_totals params={}
      page = { size: 0, number: 1 }
      page_prov = { size: 2000, number: 1 }
  
      ttl = Client.query(nil, page: page_prov, provider_id: params[:provider_id]).map do |item|    
        response = Doi.query(nil, provider_id: params[:provider_id], client_id: item.symbol.downcase, state: params[:state] || "",page: page)
        totals_formatter item, response, page
      end
      ttl
    end

    # def get_all_providers_aggs
    #   page = { size: 25, number: 1}
    #   response = Doi.query("", page: page)
    #   after = response.response.aggregations.providers_x.after_key.doi ||=""
    #   aggs  = response.response.aggregations.providers_x.buckets
    #   loop do
    #     resp = Doi.query("", {after_key: after })
    #     aggs = aggs.concat resp.response.aggregations.providers_x.buckets
    #     after = response.response.aggregations.providers_x.after_key.doi
    #     break if after.nil?
    #   end
    #   aggs
    # end
  end
end

