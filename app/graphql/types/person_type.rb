# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice"
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice"
  field :citation_count, Integer, null: true, description: "The number of citations"

  field :datasets, [DatasetType], null: true, description: "Authored datasets" do
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, [PublicationType], null: true, description: "Authored publications" do
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, [SoftwareType], null: true, description: "Authored software" do
    argument :first, Int, required: false, default_value: 25
  end

  field :works, [WorkType], null: true, description: "Authored works" do
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Person"
  end

  def datasets(**_args)
    Doi.query(nil, user_id: orcid_from_url(object[:id]), relation_type_id: "dataset", state: "findable", page: { size: args[:first], number: 1 }).results.to_a
  end

  def publications(**_args)
    Doi.query(nil, user_id: orcid_from_url(object[:id]), relation_type_id: "text", state: "findable", page: { size: args[:first], number: 1 }).results.to_a
  end

  def softwares(**_args)
    Doi.query(nil, user_id: orcid_from_url(object[:id]), relation_type_id: "software", state: "findable", page: { size: args[:first], number: 1 }).results.to_a
  end

  def works(**_args)
    Doi.query(nil, user_id: orcid_from_url(object[:id]), state: "findable", page: { size: args[:first], number: 1 }).results.to_a
  end

  def doi_count
    response.results.total.positive? ? facet_by_year(response.aggregations.years.buckets) : []
  end

  def view_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.views.buckets) : []
  end

  def download_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.downloads.buckets) : []
  end

  def citation_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.citations.buckets) : []
  end

  def response
    @response ||= Doi.query(nil, user_id: orcid_from_url(object[:id]), state: "findable", page: { number: 1, size: 0 })
  end

  def facet_by_year(arr)
    arr.map do |hsh|
      { "id" => hsh["key_as_string"][0..3],
        "title" => hsh["key_as_string"][0..3],
        "count" => hsh["doc_count"] }
    end
  end

  def aggregate_count(arr)
    arr.reduce(0) do |sum, hsh|
      sum << hsh.dig("metric_count", "value").to_i
      sum
    end
  end
end
