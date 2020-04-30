# frozen_string_literal: true

class MemberPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(MemberPrefixType)
end
