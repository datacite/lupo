# frozen_string_literal: true

class BookChapterConnectionWithTotalType < BaseConnection
  edge_type(BookChapterEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
