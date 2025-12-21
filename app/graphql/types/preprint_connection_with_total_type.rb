# frozen_string_literal: true

class PreprintConnectionWithTotalType < BaseConnection
  edge_type(PreprintEdgeType)
  implements Interfaces::WorkFacetsInterface
end
