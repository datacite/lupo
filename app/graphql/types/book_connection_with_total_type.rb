# frozen_string_literal: true

class BookConnectionWithTotalType < BaseConnection
  edge_type(BookEdgeType)
  implements Interfaces::WorkFacetsInterface
end
