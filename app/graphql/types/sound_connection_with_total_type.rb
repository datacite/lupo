# frozen_string_literal: true

class SoundConnectionWithTotalType < BaseConnection
  edge_type(SoundEdgeType)
  implements Interfaces::WorkFacetsInterface
end
