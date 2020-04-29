# frozen_string_literal: true

module Types
  class ModelEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::ModelType)
  end
end
