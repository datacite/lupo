# frozen_string_literal: true

module MetricInterface
  include GraphQL::Schema::Interface

  field :view_count, Integer, null: true, description: "The count of DOI views according to the COUNTER code of Practice"
  field :download_count, Integer, null: true, description: "The count of  DOI dowloands according to the COUNTER code of Practice"
  field :citation_count, Integer, null: true, description: "The count of DOI events that represents citations"

  def aggregation_results(**args)
    Event.query(nil, doi: doi_from_url(args[:id]), "page[size]": 0, aggregations: "metrics_aggregations", source_id: args[:source_id] || nil).response.aggregations
  end

  def view_count
    meta = aggregation_results(id: object.identifier).views.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def download_count
    meta = aggregation_results(id: object.identifier).downloads.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def citation_count
    meta = aggregation_results(id: object.identifier).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end
end
