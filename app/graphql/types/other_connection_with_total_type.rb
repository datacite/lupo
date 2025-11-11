# frozen_string_literal: true

class OtherConnectionWithTotalType < BaseConnection
  edge_type(OtherEdgeType)
  implements Interfaces::WorkFacetsInterface
end
