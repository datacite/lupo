# frozen_string_literal: true

class ImageEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ImageType)
end
