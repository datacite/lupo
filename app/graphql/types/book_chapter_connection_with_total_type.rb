# frozen_string_literal: true

class BookChapterConnectionWithTotalType < BaseConnection
  edge_type(BookChapterEdgeType)
  implements Interfaces::WorkFacetsInterface
end
