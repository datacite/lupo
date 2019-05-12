# frozen_string_literal: true

class DatasetConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(EventEdgeType, edge_class: EventEdge)
  # edge_type(EventEdgeType)
  # field :total_count, Integer, null: false

  # def total_count
  #   args = object.arguments

  #   1
  # end
end
