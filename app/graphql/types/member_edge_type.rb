# frozen_string_literal: true

class MemberEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(MemberType)
end
