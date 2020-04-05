# frozen_string_literal: true

class PublicationConnectionType < BaseConnection
  edge_type(PublicationEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :person_connection_count, Integer, null: false, cache: true
  field :funder_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true

  def total_count
    args = prepare_args(object.arguments)
    
    response(**args).results.total  
  end

  def years
    args = prepare_args(object.arguments)

    res = response(**args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : nil
  end

  def response(**args)
    @response ||= Doi.query(args[:query],
                            ids: args[:ids],
                            user_id: args[:user_id],
                            client_id: args[:client_id], 
                            provider_id: args[:provider_id],
                            funder_id: args[:funder_id], 
                            affiliation_id: args[:affiliation_id],
                            re3data_id: args[:re3data_id], 
                            year: args[:year], 
                            resource_type_id: "Text",
                            has_person: args[:has_person],
                            has_funder: args[:has_funder], 
                            has_organization: args[:has_organization], 
                            has_citations: args[:has_citations],
                            has_parts: args[:has_parts], 
                            has_versions: args[:has_versions],
                            has_views: args[:has_views], 
                            has_downloads: args[:has_downloads], 
                            page: { number: 1, size: 0 })
  end

  def publication_connection_count
    @publication_connection_count ||= Event.query(nil, citation_type: "ScholarlyArticle-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end

  def dataset_connection_count
    @dataset_connection_count ||= Event.query(nil, citation_type: "Dataset-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end

  def software_connection_count
    @software_connection_count ||= Event.query(nil, citation_type: "ScholarlyArticle-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def person_connection_count
    @person_connection_count ||= Event.query(nil, citation_type: "Person-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end

  def funder_connection_count
    @funder_connection_count ||= Event.query(nil, citation_type: "Funder-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end

  def organization_connection_count
    @organization_connection_count ||= Event.query(nil, citation_type: "Organization-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end
end
