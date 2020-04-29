# frozen_string_literal: true

module Types
  class PersonEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::PersonType)
  end
end
