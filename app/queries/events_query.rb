# frozen_string_literal: true

class EventsQuery
  include Facetable

  ACTIVE_RELATION_TYPES = [
    "cites",
    "is-supplement-by",
    "references"
  ]

  PASSIVE_RELATION_TYPES = [
     "is-cited-by",
     "is-supplemented-to",
     "is-referenced-by"
  ]

  def initialize
  end

  def doi_citations(doi)
    pid = Event.new.normalize_doi(doi)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.any? ? results.first.total.value : 0
  end

  def citations(doi)
    doi.downcase.split(",").map do |item|
      { id: item, count: EventsQuery.new.doi_citations(item) }
    end
  end

  def citations_histogram(doi)
    pid = Event.new.normalize_doi(doi)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "yearly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations.histogram.buckets
    facet_counts_by_year_month(results)
  end


  def doi_views(doi)
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def views(doi)
    doi.downcase.split(",").map do |item|
      { id: item, count: EventsQuery.new.doi_views(item) }
    end
  end

  def views_histogram(doi)
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations.histogram.buckets
    facet_counts_by_year_month(results)
  end

  def doi_downloads(doi)
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def downloads(doi)
    doi.downcase.split(",").map do |item|
      { id: item, count: EventsQuery.new.doi_downloads(item) }
    end
  end

  def downloads_histogram(doi)
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations.histogram.buckets
    facet_counts_by_year_month(results)
  end

  def usage(doi)
    doi.downcase.split(",").map do |item|
      pid = Event.new.normalize_doi(item)
      requests = EventsQuery.new.doi_downloads(doi)
      investigations = EventsQuery.new.doi_views(doi)
      { id: pid, 
        title: pid,
      relationTypes: [
        { id: "unique-dataset-requests-regular",
        title: "unique-dataset-requests-regular",
          sum: requests
        },
        { id: "unique-dataset-investigations-regular",
          title: "unique-dataset-investigations-regular",
          sum: investigations
        }
      ]
      }
    end
  end
end
