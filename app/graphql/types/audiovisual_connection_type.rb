# frozen_string_literal: true

class AudiovisualConnectionType < BaseConnection
  edge_type(AudiovisualEdgeType)
  field_class GraphQL::Cache::Field

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true

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
                            resource_type_id: "Audiovisual", 
                            has_person: args[:has_person],
                            has_funder: args[:has_funder], 
                            has_organization: args[:has_organization], 
                            has_citations: args[:has_citations], 
                            has_views: args[:has_views], 
                            has_downloads: args[:has_downloads], 
                            page: { number: 1, size: 0 })
  end
end
