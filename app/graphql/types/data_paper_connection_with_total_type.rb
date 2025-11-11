# frozen_string_literal: true

class DataPaperConnectionWithTotalType < BaseConnection
  edge_type(DataPaperEdgeType)
  implements Interfaces::WorkFacetsInterface
end
