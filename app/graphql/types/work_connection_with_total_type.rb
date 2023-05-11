# frozen_string_literal: true

class WorkConnectionWithTotalType < BaseConnection
  edge_type(WorkEdgeType)
  field_class GraphQL::Cache::Field

  implements Interfaces::WorkFacetsInterface
  field :total_count, Integer, null: false, cache: true
  field :totalCountFromCrossref,
        resolver: TotalCountFromCrossref, null: true, cache: true
  field :total_open_licenses, Integer, null: true, cache: true
  field :total_content_url, Integer, null: true, cache: true

  def total_count
    object.total_count
  end

  def total_content_url
    object.aggregations.content_url_count.value.to_i
  end

  def total_open_licenses
    object.aggregations.open_licenses.doc_count.to_i
  end



end
