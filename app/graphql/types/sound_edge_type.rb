# frozen_string_literal: true

module Types
  class SoundEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::SoundType)
  end
end
