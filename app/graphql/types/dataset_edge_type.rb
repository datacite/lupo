# frozen_string_literal: true

class Types::DatasetEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::DatasetType)
end
