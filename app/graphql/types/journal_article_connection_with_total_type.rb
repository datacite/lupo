# frozen_string_literal: true

class JournalArticleConnectionWithTotalType < BaseConnection
  edge_type(JournalArticleEdgeType)
  implements Interfaces::WorkFacetsInterface
end
