# frozen_string_literal: true

class DataCatalogEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(DataCatalogType)
end
