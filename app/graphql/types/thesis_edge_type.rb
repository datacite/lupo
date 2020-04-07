# frozen_string_literal: true

class ThesisEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ThesisType)
end
