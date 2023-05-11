# frozen_string_literal: true

class ImageConnectionWithTotalType < BaseConnection
  edge_type(ImageEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
