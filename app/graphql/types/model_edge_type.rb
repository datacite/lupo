# frozen_string_literal: true

class Types::ModelEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::ModelType)
end
