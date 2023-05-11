# frozen_string_literal: true

class AudiovisualConnectionWithTotalType < BaseConnection
  edge_type(AudiovisualEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
