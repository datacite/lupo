# frozen_string_literal: true

class PersonConnectionWithTotalType < BaseConnection  
  edge_type(PersonEdgeType)
  field_class GraphQL::Cache::Field

  # data from Tom Demeranville (ORCID) on Sep 15, 2020
  YEARS = [
    { "id" => "2012", "title" => "2012", "count" => 44270 },
    { "id" => "2013", "title" => "2013", "count" => 426775 },
    { "id" => "2014", "title" => "2014", "count" => 612300 },
    { "id" => "2015", "title" => "2015", "count" => 788650 },
    { "id" => "2016", "title" => "2016", "count" => 1068295 },
    { "id" => "2017", "title" => "2017", "count" => 1388796 },
    { "id" => "2018", "title" => "2018", "count" => 1585851 },
    { "id" => "2019", "title" => "2019", "count" => 2006672 },
  ]

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :publication_connection_count, Integer, null: false, cache: true
  field :dataset_connection_count, Integer, null: false, cache: true
  field :software_connection_count, Integer, null: false, cache: true
  field :organization_connection_count, Integer, null: false, cache: true

  def total_count
    object.total_count 
  end

  def years
    count = YEARS.reduce(0) do |sum, i|
      sum += i["count"]
      sum
    end
    this_year = object.total_count > count ? { "id" => "2020", "title" => "2020", "count" => object.total_count - count } : nil
    this_year ? YEARS << this_year : YEARS
  end
  
  def publication_connection_count
    Event.query(nil, citation_type: "Person-ScholarlyArticle", page: { number: 1, size: 0 }).results.total
  end

  def dataset_connection_count
    Event.query(nil, citation_type: "Dataset-Person", page: { number: 1, size: 0 }).results.total
  end

  def software_connection_count
    Event.query(nil, citation_type: "Person-SoftwareSourceCode", page: { number: 1, size: 0 }).results.total
  end

  def organization_connection_count
    Event.query(nil, citation_type: "Organization-Person", page: { number: 1, size: 0 }).results.total
  end
end
