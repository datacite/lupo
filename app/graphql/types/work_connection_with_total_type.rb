# frozen_string_literal: true

class WorkConnectionWithTotalType < BaseConnection
  edge_type(WorkEdgeType)
  implements Interfaces::WorkFacetsInterface

  field :totalCountFromCrossref,
        resolver: TotalCountFromCrossref, null: true
  field :total_open_licenses, Integer, null: true
  field :total_content_url, Integer, null: true
  field :resource_types, [FacetType], null: true


  def total_content_url
    object.aggregations.content_url_count.value.to_i
  end

  def total_open_licenses
    object.aggregations.open_licenses.doc_count.to_i
  end

  def resource_types
    if object.aggregations.resource_types
      arr = facet_by_combined_key(object.aggregations.resource_types.buckets)
      add_other(arr, object.aggregations.resource_types.sum_other_doc_count)
    else
      []
    end
  end
end
