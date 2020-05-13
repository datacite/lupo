# frozen_string_literal: true

class PersonEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(PersonType)
end
