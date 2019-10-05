# frozen_string_literal: true

# class PersonConnectionWithMetaType < BaseConnection  
#   edge_type(PersonEdgeType)
#   field_class GraphQL::Cache::Field
  
#   field :publication_connection_count, Integer, null: false, cache: true
#   field :dataset_connection_count, Integer, null: false, cache: true
#   field :software_connection_count, Integer, null: false, cache: true
#   field :organization_connection_count, Integer, null: false, cache: true

#   def publication_connection_count
#     Event.query(nil, citation_type: "Person-ScholarlyArticle").results.total
#   end

#   def dataset_connection_count
#     Event.query(nil, citation_type: "Dataset-Person").results.total
#   end

#   def software_connection_count
#     Event.query(nil, citation_type: "Person-SoftwareSourceCode").results.total
#   end

#   def organization_connection_count
#     Event.query(nil, citation_type: "Organization-Person").results.total
#   end
# end