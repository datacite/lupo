# frozen_string_literal: true

class ServiceConnectionWithTotalType < BaseConnection
  edge_type(ServiceEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface

  field :pid_entities, [FacetType], null: true, cache: true
  def pid_entities
    if object.aggregations.pid_entities
      facet_by_software(object.aggregations.pid_entities.subject.buckets)
    else
      []
    end
  end
end
