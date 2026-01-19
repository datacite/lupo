# frozen_string_literal: true

class ConferencePaperConnectionWithTotalType < BaseConnection
  edge_type(ConferencePaperEdgeType)
  implements Interfaces::WorkFacetsInterface
end
