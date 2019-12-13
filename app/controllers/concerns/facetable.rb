module Facetable
  extend ActiveSupport::Concern

  SOURCES = {
    "datacite-usage" => "DataCite Usage Stats",
    "datacite-resolution" => "DataCite Resolution Stats",
    "datacite-related" => "DataCite Related Identifiers",
    "datacite-crossref" => "DataCite to Crossref",
    "datacite-kisti" => "DataCite to KISTI",
    "datacite-cnki" => "DataCite to CNKI",
    "datacite-istic" => "DataCite to ISTIC",
    "datacite-medra" => "DataCite to mEDRA",
    "datacite-op" => "DataCite to OP",
    "datacite-jalc" => "DataCite to JaLC",
    "datacite-airiti" => "DataCite to Airiti",
    "datacite-url" => "DataCite URL Links",
    "datacite-funder" => "DataCite Funder Information",
    "crossref" => "Crossref to DataCite"
  }

  included do
    def facet_by_year(arr)
      arr.map do |hsh|
        { "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_annual(arr)
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

    def facet_by_affiliation(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| "\"#{hsh["key"]}\"" }.join(" ")
      affiliations = Organization.query(ids, size: 1000)[:data]

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => affiliations.find { |a| a["id"] == hsh["key"] }.to_h["name"] || hsh["key"],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_provider(arr)
      # generate hash with id and name for each provider in facet

      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_id(ids, size: 1000).records.pluck(:symbol, :name).to_h

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"].upcase],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_year_month(arr)
      arr.map do |hsh|
        month = hsh["key_as_string"][5..6].to_i
        title = I18n.t("date.month_names")[month] + " " + hsh["key_as_string"][0..3]

        { "id" => hsh["key_as_string"][0..6],
          "title" => title,
          "count" => hsh["doc_count"],
          "sum" => hsh.dig("total_by_year_month", "value") }
      end
    end

    def facet_by_source(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => SOURCES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_citations_by_year(hash)
      arr = hash.dig('years', 'buckets').map do |h|
        year = h['key']
        title = h['key'].to_i.to_s

        {
          'id' => year,
          'title' => title,
          'sum' => h.dig('total_by_year', 'value') }
      end
      { "count" => hash.dig("sum_distribution", "value"),
        "years" => arr }
    end

    def facet_citations_by_year_v1(hash)
      arr = hash.dig('years', 'buckets').map do |h|
        year = h["key_as_string"][0..3].to_i
        title = h["key_as_string"][0..3]

        {
          'id' => year,
          'title' => title,
          'sum' => h.dig('total_by_year', 'value') }
      end
      { "count" => hash.dig("sum_distribution", "value"),
        "years" => arr }
    end

    def facet_counts_by_year_month(hash)
      arr = hash.dig('year_months', 'buckets').map do |h|
        month = h["key_as_string"][5..6].to_i
        title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

        {
          "id" => h["key_as_string"][0..6],
          'title' => title,
          'sum' => h.dig('total_by_year_month', 'value') }
      end
      { "count" => hash.dig("sum_distribution", "value"),
        "yearMonths" => arr }
    end

    def facet_by_relation_type(arr)
      arr.map do |hsh|
        arr = hsh.dig("year_months", "buckets").map do |h|
          month = h["key_as_string"][5..6].to_i
          title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..6],
            "title" => title,
            "sum" => h.dig("total_by_year_month", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh.dig("sum_distribution", "value"),
          "yearMonths" => arr }
      end
    end

    def facet_by_relation_type_v1(arr)
      arr.map do |hsh|
        arr = hsh.dig("year_months", "buckets").map do |h|
          month = h["key_as_string"][5..6].to_i
          title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..6],
            "title" => title,
            "sum" => h.dig("total_by_year_month", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh.dig("sum_distribution", "value"),
          "year-months" => arr }
      end
    end

    def facet_by_citation_type(arr)
      arr.map do |hsh|
        arr = hsh.dig("year_months", "buckets").map do |h|
          month = h["key_as_string"][5..6].to_i
          title = I18n.t("date.month_names")[month] + " " + h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..6],
            "title" => title,
            "sum" => h.dig("total_by_year_month", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "year-months" => arr }
      end
    end

    def facet_by_pairings(arr)
      arr.map do |hsh|
        arr = hsh.dig("recipient", "buckets").map do |h|
          title = h["key"]
          {
            "id" => h["key"],
            "title" => title,
            "sum" => h.dig("total", "value") }
        end
        arr.reject! {|h| h["id"] == hsh["key"]}
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "registrants" => arr }
      end
    end

    def facet_by_registrants(arr)
      arr.map do |hsh|
        arr = hsh.dig("year", "buckets").map do |h|
          title = h["key_as_string"][0..3]

          {
            "id" => h["key_as_string"][0..3],
            "title" => title,
            "sum" => h.dig("total_by_year", "value") }
        end

        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "years" => arr }
      end
    end

    def facet_by_metric_type(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"].gsub(/-/, ' ').titleize,
          "count" => hsh["doc_count"] }
      end
    end
  
    def facet_by_dois(arr)
      arr.map do |hsh|
        arr = hsh.dig("relation_types", "buckets").map do |h|
          title = h["key"]
          {
            "id" => h["key"],
            "title" => title,
            "sum" => h.dig("total_by_type", "value") }
        end
        arr.reject! {|h| h["id"] == hsh["key"]}
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "relationTypes" => arr }
      end
    end

    def facet_citations_by_dois(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh.dig("total", "value")}
      end
    end

    def providers_totals(arr)
      providers = Provider.all.pluck(:symbol, :name).to_h

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"].upcase],
          "count" => hsh["doc_count"],
          "temporal" => {
            "this_month" => facet_annual(hsh.this_month.buckets),
            "this_year" => facet_annual(hsh.this_year.buckets),
            "last_year" => facet_annual(hsh.last_year.buckets),
            "two_years_ago" => facet_annual(hsh.two_years_ago.buckets)
          },
          "states"    => facet_by_key(hsh.states.buckets)
        }
      end
    end

    def prefixes_totals(arr)
      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "temporal" => {
            "this_month" => facet_annual(hsh.this_month.buckets),
            "this_year" => facet_annual(hsh.this_year.buckets),
            "last_year" => facet_annual(hsh.last_year.buckets)
          },
          "states"    => facet_by_key(hsh.states.buckets)
        }
      end
    end

    def clients_totals(arr)
      logger = LogStashLogger.new(type: :stdout)

      clients = Client.all.pluck(:symbol, :name).to_h

      arr = arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => clients[hsh["key"].upcase],
          "count" => hsh["doc_count"],
          "temporal" => {
            "this_month" => facet_annual(hsh.this_month.buckets),
            "this_year" => facet_annual(hsh.this_year.buckets),
            "last_year" => facet_annual(hsh.last_year.buckets),
            "two_years_ago" => facet_annual(hsh.two_years_ago.buckets)
          },
          "states"    => facet_by_key(hsh.states.buckets)
        }
      end
    end

    def facet_by_provider_ids(arr)
      # generate hash with id and name for each provider in facet
      ids = arr.map { |hsh| hsh["key"] }.join(",")
      providers = Provider.find_by_id_list(ids).records.pluck(:symbol, :name).to_h

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => providers[hsh["key"].upcase],
          "count" => hsh["doc_count"] }
      end
    end

    def facet_by_client(arr)
      # generate hash with id and name for each client in facet
      ids = arr.map { |hsh| hsh["key"] }.join(",")
      clients = Client.find_by_id(ids).records.pluck(:symbol, :name).to_h

      arr.map do |hsh|
        { "id" => hsh["key"],
          "title" => clients[hsh["key"].upcase],
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

