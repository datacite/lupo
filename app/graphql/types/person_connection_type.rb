# frozen_string_literal: true

module Types
  class PersonConnectionType < Types::BaseConnection  
    edge_type(Types::PersonEdgeType)
    field_class GraphQL::Cache::Field
    
    field :total_count, Integer, null: false, cache: true
    field :publication_connection_count, Integer, null: false, cache: true
    field :dataset_connection_count, Integer, null: false, cache: true
    field :software_connection_count, Integer, null: false, cache: true
    field :organization_connection_count, Integer, null: false, cache: true

    def total_count
      args = object.arguments

      Person.query(args[:query], limit: 0).dig(:meta, "total").to_i
    end

    def publication_connection_count
      Event.query(nil, citation_type: "Person-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
    end

    def dataset_connection_count
      Event.query(nil, citation_type: "Dataset-Person", page: { number: 1, size: 0 }).results.total
    end

    def software_connection_count
      Event.query(nil, citation_type: "Person-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
    end

    def organization_connection_count
      Event.query(nil, citation_type: "Organization-Person", page: { number: 1, size: 0 }).results.total
    end
  end
end