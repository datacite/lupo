# frozen_string_literal: true

class CollectionConnectionWithTotalType < BaseConnection
  edge_type(CollectionEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
