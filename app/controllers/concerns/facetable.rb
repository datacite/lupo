module Facetable
  extend ActiveSupport::Concern

  included do

    REGIONS = { 
      "amer" => "Americas",
      "apac" => "Asia Pacific",
      "emea" => "EMEA" }

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
      providers = Provider.find_by_ids(ids, size: 1000).results.reduce({}) do |sum, p|
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"]],
          "count" => hsh["doc_count"] }
      end
    end

    def providers_totals(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_ids(ids, size: 1000).results.reduce({}) do |sum, p|
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

    def prefixes_totals(arr)
      # generate hash with id and name for each provider in facet

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "temporal" => {
          "this_month" => facet_anual(hsh.this_month.buckets),
          "this_year" => facet_anual(hsh.this_year.buckets),
          "last_year" => facet_anual(hsh.last_year.buckets)},
          "states"    => facet_by_key(hsh.states.buckets)
        }
      end
    end


    def clients_totals(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| hsh["key"] }.join(",")
      clients = Client.find_by_ids(ids, size: 2000).results.reduce({}) do |sum, p|
        puts sum
        sum[p.symbol.downcase] = p.name
        sum
      end

      arr.map do |hsh|
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

