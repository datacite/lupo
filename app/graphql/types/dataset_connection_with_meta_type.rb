# frozen_string_literal: true

class DatasetConnectionWithMetaType < GraphQL::Types::Relay::BaseConnection
  edge_type(DatasetEdgeType)

  field :total_count, Integer, null: false

  def total_count
    args = object.arguments

    Doi.query(args[:query], resource_type_id: "Dataset", state: "findable", page: { number: 1, size: args[:first] }).results.total
  end
end
