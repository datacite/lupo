module Countable
  extend ActiveSupport::Concern

  included do
    def doi_count
      params = { q: "*:*",
                 fq: query_filter,
                 rows: 0,
                 fl: "doi",
                 facet: "true",
                 'facet.mincount' => 1,
                 'facet.range' => 'minted',
                 'f.minted.facet.range.start' => '2004-01-01T00:00:00Z',
                 'f.minted.facet.range.end' => '2024-01-01T00:00:00Z',
                 'f.minted.facet.range.gap' => '+1YEAR',
                 wt: "json" }.compact

      url = ENV["SOLR_HOST"] + "?" + URI.encode_www_form(params)
      result = Maremma.get url
      facets = result.body.fetch("data", {}).fetch("facet_counts", {})
      facets.fetch("facet_ranges", {}).fetch("minted", {}).fetch("counts", [])
            .each_slice(2)
            .map { |i| { id: i[0][0..3].to_i, title: i[0][0..3].to_i, count: i[1] } }
    end
  end
end
