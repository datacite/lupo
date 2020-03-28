# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."
  field :doi_count, [FacetType], null: true, description: "The number of works per year."
  field :resource_type_count, [FacetType], null: true, description: "The work types."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, DatasetConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored datasets" do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored publications"  do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored software"  do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: false, connection: true, max_page_size: 1000, description: "Authored works" do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Person"
  end

  def publications(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: orcid_from_url(object[:id]), client_id: client_id, provider_id: provider_id, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Text", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  def datasets(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: orcid_from_url(object[:id]), client_id: client_id, provider_id: provider_id, resource_type_id: "Dataset", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  def softwares(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: orcid_from_url(object[:id]), client_id: client_id, provider_id: provider_id, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Software", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  def works(query: nil, ids: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    if ids.present?
      dois = ids.split(",").map { |i| doi_from_url(i) }
      ElasticsearchLoader.for(Doi).load_many(dois)
    else
      Doi.query(query, user_id: orcid_from_url(object[:id]), client_id: client_id, provider_id: provider_id, resource_type_id: "Dataset", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
    end
  end

  def doi_count
    response.results.total.positive? ? facet_by_year(response.aggregations.years.buckets) : []
  end

  def resource_type_count
    response.results.total.positive? ? facet_by_resource_type(response.response.aggregations.resource_types.buckets) : []
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

  def facet_by_resource_type(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].underscore.dasherize,
        "title" => hsh["key"],
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
