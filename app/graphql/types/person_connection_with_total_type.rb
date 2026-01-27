# frozen_string_literal: true

class PersonConnectionWithTotalType < BaseConnection
  edge_type(PersonEdgeType)

  # data from Tom Demeranville (ORCID) on Sep 15, 2020
  YEARS = [
    { "id" => "2012", "title" => "2012", "count" => 44_270 },
    { "id" => "2013", "title" => "2013", "count" => 426_775 },
    { "id" => "2014", "title" => "2014", "count" => 612_300 },
    { "id" => "2015", "title" => "2015", "count" => 788_650 },
    { "id" => "2016", "title" => "2016", "count" => 1_068_295 },
    { "id" => "2017", "title" => "2017", "count" => 1_388_796 },
    { "id" => "2018", "title" => "2018", "count" => 1_585_851 },
    { "id" => "2019", "title" => "2019", "count" => 2_006_672 },
  ].freeze

  field :total_count, Integer, null: false
  field :years, [FacetType], null: true
  field :publication_connection_count, Integer, null: false
  field :dataset_connection_count, Integer, null: false
  field :software_connection_count, Integer, null: false
  field :organization_connection_count, Integer, null: false

  def total_count
    object.total_count
  end

  def years
    count =
      YEARS.dup.reduce(0) do |sum, i|
        sum += i["count"]
        sum
      end
    this_year =
      if object.total_count > count
        {
          "id" => "2021",
          "title" => "2021",
          "count" => object.total_count - count,
        }
      end
    this_year ? YEARS.dup << this_year : YEARS
  end

  def publication_connection_count
    Event.query(
      nil,
      citation_type: "Person-ScholarlyArticle", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def dataset_connection_count
    Event.query(
      nil,
      citation_type: "Dataset-Person", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def software_connection_count
    Event.query(
      nil,
      citation_type: "Person-SoftwareSourceCode", page: { number: 1, size: 0 },
    ).
      results.
      total
  end

  def organization_connection_count
    Event.query(
      nil,
      citation_type: "Organization-Person", page: { number: 1, size: 0 },
    ).
      results.
      total
  end
end
