# frozen_string_literal: true

class DatasetConnectionWithMetaType < BaseConnection
  edge_type(DatasetEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :researcher_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true
  
  field :views_connection_count, Integer, null: true, cache: true
  field :downloads_connection_count, Integer, null: true, cache: true
  field :citations_connection_count, Integer, null: true, cache: true 


  def total_count
    args = object.arguments

    Doi.query(args[:query], resource_type_id: "Dataset", state: "findable", page: { number: 1, size: args[:first] }).results.total
  end

  def dataset_connection_count
    Event.query(nil, citation_type: "Dataset-Dataset").results.total
  end

  def publication_connection_count
    Event.query(nil, citation_type: "Dataset-ScholarlyArticle").results.total
  end

  def software_connection_count
    Event.query(nil, citation_type: "Dataset-SoftwareSourceCode").results.total
  end

  def researcher_connection_count
    Event.query(nil, citation_type: "Dataset-Person").results.total
  end

  def funder_connection_count
    Event.query(nil, citation_type: "Dataset-Funder").results.total
  end

  def organization_connection_count
    Event.query(nil, citation_type: "Dataset-Organization").results.total
  end

  def aggregation_results args
    Event.query(nil, doi: doi_from_url(args[:query]), "page[size]": 0,aggregations: "metrics_aggregations").response.aggregations
  end

  # def views_connection_count
  #   args = object.arguments
  #   aggregation = Event.query(nil, doi: doi_from_url(args[:query]), "page[size]": 0,aggregations: "metrics_aggregations").response.aggregations
  #   views = aggregation.views.dois.buckets
  #   views = views.first.fetch("doc_count", nil) if views.any?

  #   downloads = aggregation.downloads.dois.buckets
  #   downloads = downloads.first.fetch("doc_count", nil) if downloads.any?

  #   citations = aggregation.citations.dois.buckets
  #   citations = citations.first.fetch("unique_citations", {}).fetch("value", nil) if citations.any?
  #   {
  #     views: views,
  #     downloads: downloads,
  #     citations: citations
  #   }
  # end

  def views_connection_count
    args = object.arguments
    meta = aggregation_results(args).views.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def downloads_connection_count
    args = object.arguments
    meta = aggregation_results(args).downloads.dois.buckets
    meta.first.fetch("total_by_type", {}).fetch("value", nil) if meta.any?
  end

  def citations_connection_count
    args = object.arguments
    meta = aggregation_results(args).citations.dois.buckets
    meta.first.fetch("unique_citations", {}).fetch("value", nil) if meta.any?
  end
end
