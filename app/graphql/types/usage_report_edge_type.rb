# frozen_string_literal: true

module Types
  class UsageReportEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::UsageReportType)
  end
end
