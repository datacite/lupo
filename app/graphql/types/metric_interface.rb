# frozen_string_literal: true

module MetricInterface
  include GraphQL::Schema::Interface

  field :views_count, Integer, null: true, description: "The count of DOI views according to the COUNTER code of Practice for Research Data"
  field :downloads_count, Integer, null: true, description: "The count of  DOI dowloands according to the COUNTER code of Practice for Research Data"
  field :citations_count, Integer, null: true, description: "The count of DOI events that represents citations"
  field :crossref_citations_count, Integer, null: true, description: "The count of DOI events that represents citations from Crossref"
  field :datacite_citations_count, Integer, null: true, description: "The count of DOI events that represents citations from DataCite"

  def aggregation_results(**args)
    Event.query(nil, doi: doi_from_url(args[:id]), "page[size]": 0, aggregations: "metrics_aggregations", source_id: args[:source_id] || nil).response.aggregations
  end

  def views_count
    meta = aggregation_results(id: object.identifier).views.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def downloads_count
    meta = aggregation_results(id: object.identifier).downloads.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def citations_count
    meta = aggregation_results(id: object.identifier).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end

  def crossref_citations_count
    args = {
      id: object.identifier,
      source_id: "crossref"
    }
    meta = aggregation_results(args).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end

  def datacite_citations_count
    args = {
      id: object.identifier,
      source_id: "datacite-related,datacite-crossref"
    }
    meta = aggregation_results(args).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end
end
