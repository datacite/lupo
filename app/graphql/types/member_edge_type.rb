# frozen_string_literal: true

class Types::MemberEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::MemberType)
end
