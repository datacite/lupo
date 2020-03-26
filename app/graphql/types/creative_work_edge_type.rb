# frozen_string_literal: true

class CreativeWorkEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(WorkType)
end
