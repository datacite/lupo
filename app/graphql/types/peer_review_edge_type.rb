# frozen_string_literal: true

class Types::PeerReviewEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PeerReviewType)
end
