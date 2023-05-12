# frozen_string_literal: true

class PeerReviewConnectionWithTotalType < BaseConnection
  edge_type(PeerReviewEdgeType)
  field_class GraphQL::Cache::Field
  implements Interfaces::WorkFacetsInterface
end
