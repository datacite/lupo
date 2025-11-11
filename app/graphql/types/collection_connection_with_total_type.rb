# frozen_string_literal: true

class CollectionConnectionWithTotalType < BaseConnection
  edge_type(CollectionEdgeType)
  implements Interfaces::WorkFacetsInterface
end
