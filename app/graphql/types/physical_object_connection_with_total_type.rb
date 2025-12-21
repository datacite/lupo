# frozen_string_literal: true

class PhysicalObjectConnectionWithTotalType < BaseConnection
  edge_type(PhysicalObjectEdgeType)
  implements Interfaces::WorkFacetsInterface
end
