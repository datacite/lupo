# frozen_string_literal: true

class SoundConnectionWithTotalType < BaseConnection
  edge_type(SoundEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
