# frozen_string_literal: true

class Types::DataCatalogEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::DataCatalogType)
end
