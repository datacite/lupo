# frozen_string_literal: true

class OrganizationConnectionWithTotalType < BaseConnection
  edge_type(OrganizationEdgeType)

  # data from GRID taken on Oct 18, 2020 https://grid.ac/downloads
  # using latest release in any given year, starting with end of 2017,
  # right before ROR was launched in January 2018
  YEARS = [
    { "id" => "2017", "title" => "2017", "count" => 80_248 },
    { "id" => "2018", "title" => "2018", "count" => 11_392 },
    { "id" => "2019", "title" => "2019", "count" => 6_179 },
  ].freeze

  field :total_count, Integer, null: false
  field :years, [FacetType], null: true
  field :types, [FacetType], null: true
  field :countries, [FacetType], null: true
  field :person_connection_count, Integer, null: false

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
    @person_connection_count ||=
      Event.query(nil, citation_type: "Organization-Person").results.total
  end
end
