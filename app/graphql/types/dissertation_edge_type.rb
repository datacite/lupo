# frozen_string_literal: true

module Types
  class DissertationEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::DissertationType)
  end
end
