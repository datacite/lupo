# frozen_string_literal: true

class Types::SoundEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::SoundType)
end
