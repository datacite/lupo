# frozen_string_literal: true

class OrganizationConnectionWithTotalType < BaseConnection
  edge_type(OrganizationEdgeType)
  field_class GraphQL::Cache::Field

  # data from GRID taken on Oct 18, 2020 https://grid.ac/downloads
  # using latest release in any given year, starting with end of 2017,
  # right before ROR was launched in January 2018
  YEARS = [
    { "id" => "2017", "title" => "2017", "count" => 80248 },
    { "id" => "2018", "title" => "2018", "count" => 11392 },
    { "id" => "2019", "title" => "2019", "count" => 6179 },
  ]

  field :total_count, Integer, null: false, cache: true
  field :years, [FacetType], null: true, cache: true
  field :types, [FacetType], null: true, cache: true
  field :countries, [FacetType], null: true, cache: true
  field :person_connection_count, Integer, null: false, cache: true

  def years
    count = YEARS.reduce(0) do |sum, i|
      sum += i["count"]
      sum
    end
    this_year = object.total_count > count ? { "id" => "2020", "title" => "2020", "count" => object.total_count - count } : nil
    this_year ? YEARS << this_year : YEARS
  end

  def total_count
    object.total_count
  end

  def types
    object.meta["types"]
  end

  def countries
    object.meta["countries"]
  end

  def person_connection_count
    @person_connection_count ||= Event.query(nil, citation_type: "Organization-Person").results.total
  end
end
