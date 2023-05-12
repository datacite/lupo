# frozen_string_literal: true

class JournalArticleConnectionWithTotalType < BaseConnection
  edge_type(JournalArticleEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
