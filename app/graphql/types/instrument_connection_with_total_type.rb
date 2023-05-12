# frozen_string_literal: true

class InstrumentConnectionWithTotalType < BaseConnection
  edge_type(InstrumentEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
