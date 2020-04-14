# frozen_string_literal: true

class DissertationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(DissertationType)
end
