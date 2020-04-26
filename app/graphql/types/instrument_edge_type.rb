# frozen_string_literal: true

class Types::InstrumentEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::InstrumentType)
end
