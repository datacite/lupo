# frozen_string_literal: true

class Types::MemberPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::MemberPrefixType)
end
