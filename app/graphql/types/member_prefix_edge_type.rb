# frozen_string_literal: true

module Types
  class MemberPrefixEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::MemberPrefixType)
  end
end
