# frozen_string_literal: true

class ModelConnectionWithTotalType < BaseConnection
  edge_type(ModelEdgeType)
  implements Interfaces::WorkFacetsInterface
end
