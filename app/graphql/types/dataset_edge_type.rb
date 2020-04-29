# frozen_string_literal: true

module Types
  class DatasetEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::DatasetType)
  end
end
