# frozen_string_literal: true

module Types
  class DatasetConnectionType < Types::BaseConnection
    edge_type(Types::DatasetEdgeType)
    field_class GraphQL::Cache::Field

    field :total_count, Integer, null: false, cache: true
    field :years, [Types::FacetType], null: true, cache: true
    field :registration_agencies, [Types::FacetType], null: true, cache: true
    field :repositories, [Types::FacetType], null: true, cache: true
    field :affiliations, [Types::FacetType], null: true, cache: true

    field :dataset_connection_count, Integer, null: false, cache: true
    field :publication_connection_count, Integer, null: false, cache: true
    field :software_connection_count, Integer, null: false, cache: true
    field :person_connection_count, Integer, null: false, cache: true
    field :funder_connection_count, Integer, null: false, cache: true
    field :organization_connection_count, Integer, null: false, cache: true

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
      res.results.total.positive? ? facet_by_combined_key(res.response.aggregations.clients.buckets) : []
    end

    def affiliations
      args = prepare_args(object.arguments)

      res = response(args)
      res.results.total.positive? ? facet_by_combined_key(res.response.aggregations.affiliations.buckets) : []
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
                resource_type_id: "Dataset", 
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

    def dataset_connection_count
      @dataset_connection_count ||= Event.query(nil, citation_type: "Dataset-Dataset", page: { number: 1, size: 0 }).results.total
    end

    def publication_connection_count
      @publication_connection_count ||= Event.query(nil, citation_type: "Dataset-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
    end

    def software_connection_count
      @software_connection_count ||= Event.query(nil, citation_type: "Dataset-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
    end

    def person_connection_count
      @person_connection_count ||= Event.query(nil, citation_type: "Dataset-Person", page: { number: 1, size: 0 }).results.total
    end

    def funder_connection_count
      @funder_connection_count ||= Event.query(nil, citation_type: "Dataset-Funder", page: { number: 1, size: 0 }).results.total
    end

    def organization_connection_count
      @organization_connection_count ||= Event.query(nil, citation_type: "Dataset-Organization", page: { number: 1, size: 0 }).results.total
    end
  end
end
