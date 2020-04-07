# frozen_string_literal: true

class InstrumentEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(InstrumentType)
end
