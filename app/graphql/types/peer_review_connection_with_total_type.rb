# frozen_string_literal: true

class PeerReviewConnectionWithTotalType < BaseConnection
  edge_type(PeerReviewEdgeType)
  implements Interfaces::WorkFacetsInterface
end
