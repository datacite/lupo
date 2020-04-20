# frozen_string_literal: true

class ModelEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ModelType)
end
