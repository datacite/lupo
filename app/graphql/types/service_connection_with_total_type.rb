# frozen_string_literal: true

class ServiceConnectionWithTotalType < BaseConnection
  edge_type(ServiceEdgeType)
  implements Interfaces::WorkFacetsInterface

  field :pid_entities, [FacetType], null: true, cache_fragment: true
  def pid_entities
    if object.aggregations.pid_entities
      facet_by_software(object.aggregations.pid_entities.subject.buckets)
    else
      []
    end
  end
end
