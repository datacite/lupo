# frozen_string_literal: true

class Types::PersonEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::PersonType)
end