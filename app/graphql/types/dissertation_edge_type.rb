# frozen_string_literal: true

class Types::DissertationEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::DissertationType)
end
