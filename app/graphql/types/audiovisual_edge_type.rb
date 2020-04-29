# frozen_string_literal: true

module Types
  class AudiovisualEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::AudiovisualType)
  end
end
