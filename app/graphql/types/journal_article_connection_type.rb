# frozen_string_literal: true

class JournalArticleConnectionType < BaseConnection
  edge_type(JournalArticleEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :registration_agencies, [FacetType], null: true, cache: true
  field :repositories, [FacetType], null: true, cache: true
  field :affiliations, [FacetType], null: true, cache: true

  def total_count
    args = prepare_args(object.arguments)
    
    response(args).results.total  
  end

  def years
    args = prepare_args(object.arguments)

    res = response(args)
    res.results.total.positive? ? facet_by_year(res.response.aggregations.years.buckets) : []
  end

  def registration_agencies
    args = prepare_args(object.arguments)

    res = response(args)
    res.results.total.positive? ? facet_by_software(res.response.aggregations.registration_agencies.buckets) : []
  end

  def repositories
    args = prepare_args(object.arguments)

    res = response(args)
    res.results.total.positive? ? facet_by_client(res.response.aggregations.clients.buckets) : []
  end

  def affiliations
    args = prepare_args(object.arguments)

    res = response(args)
    res.results.total.positive? ? facet_by_affiliation(res.response.aggregations.affiliations.buckets) : []
  end

  def response(**args)
    Doi.query(args[:query],
              ids: args[:ids],
              user_id: args[:user_id], 
              client_id: args[:repository_id], 
              provider_id: args[:member_id],
              funder_id: args[:funder_id], 
              affiliation_id: args[:affiliation_id],
              re3data_id: args[:re3data_id], 
              year: args[:year], 
              resource_type_id: "Text",
              resource_type: "JournalArticle",
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
end
