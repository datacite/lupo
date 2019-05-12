# frozen_string_literal: true

class OrganizationConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(OrganizationEdgeType)

  field :total_count, Integer, null: false

  def total_count
    args = object.arguments

    Organization.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
