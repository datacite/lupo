# frozen_string_literal: true

class FunderConnectionWithMetaType < BaseConnection
  edge_type(FunderEdgeType)

  field :total_count, Integer, null: false

  def total_count
    args = object.arguments

    Funder.query(args[:query], limit: 0).dig(:meta, "total").to_i
  end
end
