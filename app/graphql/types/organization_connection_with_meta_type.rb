# frozen_string_literal: true

class OrganizationConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(OrganizationEdgeType)

  field :total_count, Integer, null: false

  def total_count
    object.nodes.size
  end
end
