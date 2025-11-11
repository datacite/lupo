# frozen_string_literal: true

class DissertationConnectionWithTotalType < BaseConnection
  edge_type(DissertationEdgeType)
  implements Interfaces::WorkFacetsInterface
end
