# frozen_string_literal: true

class Types::AudiovisualEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::AudiovisualType)
end
