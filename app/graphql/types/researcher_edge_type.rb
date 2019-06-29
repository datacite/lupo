# frozen_string_literal: true

class ResearcherEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(ResearcherType)
end
