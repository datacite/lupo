# frozen_string_literal: true

class InstrumentConnectionWithTotalType < BaseConnection
  edge_type(InstrumentEdgeType)
  implements Interfaces::WorkFacetsInterface
end
