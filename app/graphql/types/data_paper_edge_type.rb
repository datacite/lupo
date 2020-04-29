# frozen_string_literal: true

module Types
  class DataPaperEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::DataPaperType)
  end
end
