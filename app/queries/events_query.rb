# frozen_string_literal: true

class EventsQuery
  attr_reader :relation

  include Facetable

  ACTIVE_RELATION_TYPES = [
    "cites",
    "is-supplement-to",
    "references"
  ]

  PASSIVE_RELATION_TYPES = [
     "is-cited-by",
     "is-supplemented-by",
     "is-referenced-by"
  ]

  def initialize(relation = Event.new)
    @relation = relation
  end

  def doi_citations(doi)
    pid = relation.normalize_doi(doi)
    query = "(subj_id:\"#{pid}\" AND (relation_type_id:#{PASSIVE_RELATION_TYPES.join(' OR relation_type_id:')})) OR (obj_id:\"#{pid}\" AND (relation_type_id:#{ACTIVE_RELATION_TYPES.join(' OR relation_type_id:')}))"
    results = Event.query(query, doi:doi, aggregations: "citation_count_aggregation", page: { size: 1, cursor: [] }).response.aggregations.citations.buckets
    results.any? ? results.first.total.value : 0
  end

  def citations(doi)
    doi.downcase.split(",").map do |item|
      { id: item, count: EventsQuery.new.doi_citations(item) }
    end
  end


end
