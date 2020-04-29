# frozen_string_literal: true

module Types
  class ImageEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::ImageType)
  end
end
