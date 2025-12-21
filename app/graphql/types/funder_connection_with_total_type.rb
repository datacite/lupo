# frozen_string_literal: true

class FunderConnectionWithTotalType < BaseConnection
  edge_type(FunderEdgeType)

  field :total_count, Integer, null: false
  field :publication_connection_count, Integer, null: false
  field :dataset_connection_count, Integer, null: false
  field :software_connection_count, Integer, null: false

  def total_count
    object.total_count
  end

  def publication_connection_count
    @publication_connection_count ||=
      Event.query(nil, citation_type: "Funder-ScholarlyArticle").results.total
  end

  def dataset_connection_count
    @dataset_connection_count ||=
      Event.query(nil, citation_type: "Dataset-Funder").results.total
  end

  def software_connection_count
    @software_connection_count ||=
      Event.query(nil, citation_type: "Funder-SoftwareSourceCode").results.total
  end
end
