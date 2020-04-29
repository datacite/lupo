# frozen_string_literal: true

module Types
  class DataCatalogEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::DataCatalogType)
  end
end
