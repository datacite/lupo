# frozen_string_literal: true

require "pp"

class EventsQuery
  include Facetable
  include Helpable
  include Modelable

  ACTIVE_RELATION_TYPES = [
    "cites",
    "is-supplemented-by",
    "references",
  ].freeze

  PASSIVE_RELATION_TYPES = [
    "is-cited-by",
    "is-supplement-to",
    "is-referenced-by",
  ].freeze

  def initialize; end

  def doi_citations(doi)
    return nil if doi.blank?

    pid = Event.new.normalize_doi(doi)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.any? ? results.first.total.value : 0
  end

  def citations_left_query(dois, pids)
    return nil if dois.blank?

    # pids = dois.split(",").map do |doi|
    #   Event.new.normalize_doi(doi)
    # end.uniq
    query = "((subj_id:\"#{pids.join('" OR subj_id:"')}\" ) AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: dois, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.map do |item|
      { id: item[:key], citations: item.total.value }
    end
  end

  def citations_right_query(dois, pids)
    return nil if dois.blank?

    # pids = dois.split(",").map do |doi|
    #   Event.new.normalize_doi(doi)
    # end.uniq
    query = "((obj_id:\"#{pids.join('" OR obj_id:"')}\") AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: dois, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.map do |item|
      { id: item[:key], citations: item.total.value }
    end
  end

  def citations(dois)
    return [] if dois.blank?

    pids = dois.split(",").map do |doi|
      Event.new.normalize_doi(doi)
    end
    
    right = citations_right_query(dois, pids)
    left  = citations_left_query(dois, pids)
    hashes = merge_array_hashes(right, left)

    dois_array = dois.split(",").map { |doi| doi }

    dois_array.map do |doi|
      result = hashes.select { |item| item[:id] == doi.downcase }.first
      count = result.nil? ? 0 : result[:citations]
      { id: doi.downcase, citations: count }
    end
  end

  def citations_histogram(doi)
    return {} if doi.blank?

    pid = Event.new.normalize_doi(doi.downcase.split(",").first)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "yearly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_citations_by_year(results)
  end

  def doi_views(doi)
    return nil if doi.blank?

    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def views(dois)
    return {} if dois.blank?

    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: dois, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets

    # results.map do |item|
    #   { id: doi_from_url(item[:key]), views: item.dig("total_by_type", "value") }
    # end

    dois_array = dois.split(",").map { |doi| doi }
    dois_array.map do |doi|
      result = results.select { |item| doi_from_url(item[:key]) == doi }.first
      count = result.nil? ? 0 : result.dig("total_by_type", "value")
      { id: doi, views: count }
    end
  end

  def views_histogram(doi)
    return {} if doi.blank?

    doi = doi.downcase.split(",").first
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_counts_by_year_month(results)
  end

  def doi_downloads(doi)
    return nil if doi.blank?

    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def downloads(dois)
    return {} if dois.blank?

    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: dois, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets

    # results.map do |item|
    #   { id: doi_from_url(item[:key]), downloads: item.dig("total_by_type", "value") }
    # end

    dois_array = dois.split(",").map { |doi| doi }
    dois_array.map do |doi|
      result = results.select { |item| doi_from_url(item[:key]) == doi }.first
      count = result.nil? ? 0 : result.dig("total_by_type", "value")
      { id: doi, downloads: count }
    end
  end

  def downloads_histogram(doi)
    return {} if doi.blank?

    doi = doi.downcase.split(",").first
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_counts_by_year_month(results)
  end

  def views_and_downloads(dois)
    return [] if dois.blank?

    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage) OR (relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: dois, aggregations: "multiple_usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations

    dois_array = dois.split(",").map { |doi| doi }
    dois_array.map do |doi|
      bucket = results.usage.buckets.select { |item| item[:key] == "https://doi.org/#{doi.downcase}" }.first
      if bucket.nil?
        { id: doi.downcase, downloads: 0, views: 0 }
      else
        views = bucket.relation_types.buckets.select { |item| item["key"] == "unique-dataset-investigations-regular" }.first
        downloads = bucket.relation_types.buckets.select { |item| item["key"] == "unique-dataset-requests-regular" }.first
        views_counts = views.nil? ? 0 : views.dig("total_by_type", "value")
        downloads_counts = downloads.nil? ? 0 : downloads.dig("total_by_type", "value")
        { id: doi.downcase, downloads: downloads_counts, views: views_counts }
      end
    end
  end

  def usage(doi)
    return {} if doi.blank?

    doi.downcase.split(",").map do |item|
      pid = Event.new.normalize_doi(item)
      requests = EventsQuery.new.doi_downloads(item)
      investigations = EventsQuery.new.doi_views(item)
      { id: pid,
        title: pid,
        relationTypes: [
          { id: "unique-dataset-requests-regular",
            title: "unique-dataset-requests-regular",
            sum: requests },
          { id: "unique-dataset-investigations-regular",
            title: "unique-dataset-investigations-regular",
            sum: investigations },
        ] }
    end
  end
end
