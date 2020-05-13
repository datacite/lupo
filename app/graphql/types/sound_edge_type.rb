# frozen_string_literal: true

class SoundEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(SoundType)
end
