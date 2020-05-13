# frozen_string_literal: true

class PeerReviewEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PeerReviewType)
end
