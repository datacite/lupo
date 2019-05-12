# frozen_string_literal: true

class DatasetEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(DatasetType)
end
