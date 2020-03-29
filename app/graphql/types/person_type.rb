# frozen_string_literal: true

class PersonType < BaseObject
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."
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

  field :works, WorkConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored works" do
    argument :query, String, required: false
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

  def works(query: nil, client_id: nil, provider_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: orcid_from_url(object[:id]), client_id: client_id, provider_id: provider_id, resource_type_id: "Dataset", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
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
end
