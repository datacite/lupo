# frozen_string_literal: true

class EventsQuery
  include Facetable
  include BatchLoaderHelper


  ACTIVE_RELATION_TYPES = [
    "cites",
    "is-supplemented-by",
    "references"
  ]

  PASSIVE_RELATION_TYPES = [
     "is-cited-by",
     "is-supplement-to",
     "is-referenced-by"
  ]

  def initialize
  end

  def doi_citations(doi)
    return nil unless doi.present?
    pid = Event.new.normalize_doi(doi)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.any? ? results.first.total.value : 0
  end

  # def citations(doi)
  #   return {} unless doi.present?
  #   array = doi.downcase.split(",").uniq
  #   array.map do |item|
  #     { id: item, count: EventsQuery.new.doi_citations(item) }
  #   end
  # end

  def citations_left_query(dois)
    return nil unless dois.present?
    pids = dois.split(",").map do |doi|
      Event.new.normalize_doi(doi)
    end.uniq
    query = "((subj_id:\"#{pids.join('" OR subj_id:"')}\" ) AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: dois, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.map do |item|
      { id: item[:key], citations: item.total.value }
    end
  end

  def citations_right_query(dois)
    return nil unless dois.present?
    pids = dois.split(",").map do |doi|
      Event.new.normalize_doi(doi)
    end.uniq
    query = "((obj_id:\"#{pids.join('" OR obj_id:"')}\") AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: dois, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.map do |item|
      { id: item[:key], citations: item.total.value }
    end
  end

  def citations(dois)
    right = citations_right_query(dois)
    left  = citations_left_query(dois)
    merge_array_hashes(right, left)
  end

  def merge_array_hashes(first_array, second_array)
    return first_array if second_array.blank?
    return second_array if first_array.blank?

    total = first_array | second_array
    total.group_by {|hash| hash[:id]}.map do |key, value|
      metrics = value.reduce(&:merge)
      {id: key}.merge(metrics)
    end
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def load_citation_events(doi)
    # results.any? ? results.first.total.value : 0
    BatchLoader.for(doi).batch do |event_ids, loader|
      pid = Event.new.normalize_doi(doi)
      query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"  
      Event.query(query, doi: event_ids.join(","), aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets.each do |event| 
        loader.call(event.uuid, event.total.value)
      end
    end
  end

  def citations_histogram(doi)
    return {} unless doi.present?
    pid = Event.new.normalize_doi(doi.downcase.split(",").first)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi: doi, aggregations: "yearly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_citations_by_year(results)
  end

  def doi_views(doi)
    return nil unless doi.present?
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def views(dois)
    return {} unless dois.present?
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: dois, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets

    results.map do |item|
      { id: doi_from_url(item[:key]), views: item.dig("total_by_type", "value") }
    end
  end


  def load_view_events(doi)
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    BatchLoader.for(doi).batch do |event_ids, loader|
      Event.query(query, doi: event_ids.join(","), aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations.each do |event| 
        loader.call(event.uuid, event.dig("total_by_type", "value"))
      end
    end
  end

  def views_histogram(doi)
    return {} unless doi.present?
    doi = doi.downcase.split(",").first
    query = "(relation_type_id:unique-dataset-investigations-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_counts_by_year_month(results)
  end

  def doi_downloads(doi)
    return nil unless doi.present?
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets
    results.any? ? results.first.dig("total_by_type", "value") : 0
  end

  def downloads(dois)
    return {} unless dois.present?
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: dois, aggregations: "usage_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.usage.buckets

    results.map do |item|
      { id: doi_from_url(item[:key]), downloads: item.dig("total_by_type", "value") }
    end
  end

  def downloads_histogram(doi)
    return {} unless doi.present?
    doi = doi.downcase.split(",").first
    query = "(relation_type_id:unique-dataset-requests-regular AND source_id:datacite-usage)"
    results = Event.query(query, doi: doi, aggregations: "monthly_histogram_aggregation", page: { size: 1, cursor: [] }).response.aggregations
    facet_counts_by_year_month(results)
  end

  def usage(doi)
    return {} unless doi.present?
    doi.downcase.split(",").map do |item|
      pid = Event.new.normalize_doi(item)
      requests = EventsQuery.new.doi_downloads(item)
      investigations = EventsQuery.new.doi_views(item)
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
