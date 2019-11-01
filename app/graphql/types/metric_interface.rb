# frozen_string_literal: true

module MetricInterface
  include GraphQL::Schema::Interface

  field :view_count, Integer, null: true, description: "The count of DOI views according to the COUNTER code of Practice"
  field :download_count, Integer, null: true, description: "The count of  DOI dowloands according to the COUNTER code of Practice"
  field :citation_count, Integer, null: true, description: "The count of DOI events that represents citations"
  field :reference_count, Integer, null: true, description: "The count of DOI events that represents references"
  field :relation_count, Integer, null: true, description: "The count of DOI events that represents relations"
  # field :citations_list, [String], null: true, description: "List of DOIS citing a given DOI"
  # field :referenceslist, [String], null: true, description: "List of DOIS that a given DOI references to"
  # field :relations_list, [String], null: true, description: "List of DOIS relations a given DOI has"
  
  def aggregation_results(**args)
    Event.query(nil, doi: doi_from_url(args[:id]), "page[size]": 0, aggregations: args[:aggregations] || "metrics_aggregations", source_id: args[:source_id] || nil).response.aggregations
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
    meta = citations_aggs
    meta.first.fetch("total", {}).fetch("value", nil) if meta.any?
  end

  def reference_count
    meta = references_aggs
    meta.first.fetch("total", {}).fetch("value", nil) if meta.any?
  end

  def relation_count
    meta = relations_aggs
    meta.first.fetch("total", {}).fetch("value", nil) if meta.any?
  end

  # def references_list
  #   references_aggs.map { |item| item[:key]}
  # end

  # def relations_list
  #   relations_aggs.map { |item| item[:key]}
  # end

  # def citations_list
  #   citations_aggs.map { |item| item[:key]}
  #   # citations_aggs.map do |item| 
  #   #   puts item[:key]
  #   #   puts Doi.find_by_id(item[:key]).results.first
  #   # end
  # end

  def citations_aggs
    aggregation_results(id: object.identifier, aggregations: "citations_aggregations" ).citations.dois.buckets 
  end

  def references_aggs
    aggregation_results(id: object.identifier, aggregations: "citations_aggregations").references.dois.buckets
  end

  def relations_aggs
    aggregation_results(id: object.identifier, aggregations: "citations_aggregations").relations.dois.buckets
  end
end
