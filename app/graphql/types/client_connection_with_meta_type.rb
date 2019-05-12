# frozen_string_literal: true

class ClientConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(ClientEdgeType)

  field :total_count, Integer, null: false

  def total_count
    object.nodes.size
  end
end
