# frozen_string_literal: true

class BookConnectionWithTotalType < BaseConnection
  edge_type(BookEdgeType)
  implements Interfaces::WorkFacetsInterface
  field_class GraphQL::Cache::Field
end
