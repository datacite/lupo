# frozen_string_literal: true

module Types
  class MemberEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::MemberType)
  end
end
