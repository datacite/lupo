# frozen_string_literal: true

class DataPaperEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(DataPaperType)
end
