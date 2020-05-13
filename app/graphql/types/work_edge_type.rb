# frozen_string_literal: true

class WorkEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(WorkType)
end
