# frozen_string_literal: true

class Types::UsageReportEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::UsageReportType)
end
