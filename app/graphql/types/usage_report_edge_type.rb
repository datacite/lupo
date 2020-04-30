# frozen_string_literal: true

class UsageReportEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(UsageReportType)
end
