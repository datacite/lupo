# frozen_string_literal: true

class ImageConnectionWithTotalType < BaseConnection
  edge_type(ImageEdgeType)
  implements Interfaces::WorkFacetsInterface
end
