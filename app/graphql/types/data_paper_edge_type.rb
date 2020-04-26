# frozen_string_literal: true

class Types::DataPaperEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::DataPaperType)
end
