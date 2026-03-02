# frozen_string_literal: true

class InteractiveResourceConnectionWithTotalType < BaseConnection
  edge_type(InteractiveResourceEdgeType)
  implements Interfaces::WorkFacetsInterface
end
