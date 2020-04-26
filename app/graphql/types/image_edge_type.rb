# frozen_string_literal: true

class Types::ImageEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::ImageType)
end
