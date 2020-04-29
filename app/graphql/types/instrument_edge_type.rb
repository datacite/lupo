# frozen_string_literal: true

module Types
  class InstrumentEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::InstrumentType)
  end
end
