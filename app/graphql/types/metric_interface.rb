# frozen_string_literal: true

module MetricInterface
  include GraphQL::Schema::Interface
  
  field :views, Integer, null: true, description: "The count of  doi views"
  field :downloads, Integer, null: true, description: "The count of  doi downloads"
  field :citations, Integer, null: true, description: "The count of doi events that represents citations"
  field :crossref_citations, Integer, null: true, description: "The count of doi events that represents citations from Crossref"
  field :datacite_citations, Integer, null: true, description: "The count of doi events that represents citations from DataCite"

  def aggregation_results(**args)
    Event.query(nil, doi: doi_from_url(args[:id]), "page[size]": 0,aggregations: "metrics_aggregations", source_id: args[:source_id] || nil ).response.aggregations
  end

  def views
    meta = aggregation_results({id: object.identifier}).views.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def downloads
    meta = aggregation_results({id: object.identifier}).downloads.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def citations
    meta = aggregation_results({id: object.identifier}).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end

  def crossref_citations
    args = {
      id: object.identifier,
      source_id: "crossref"
    }
    meta = aggregation_results(args).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end

  def datacite_citations
    args = {
      id: object.identifier,
      source_id: "datacite"
    }
    meta = aggregation_results(args).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end
end
