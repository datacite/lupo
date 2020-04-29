# frozen_string_literal: true

module Types
  class PeerReviewEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PeerReviewType)
  end
end
