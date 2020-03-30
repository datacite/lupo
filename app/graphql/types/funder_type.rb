# frozen_string_literal: true

class FunderType < BaseObject
  description "Information about funders"

  field :id, ID, null: false, description: "Crossref Funder ID"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "The name of the funder."
  field :alternate_name, [String], null: true, description: "An alias for the funder."
  field :address, AddressType, null: true, description: "Physical address of the funder."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, DatasetConnectionWithMetaType, null: true, description: "Funded datasets", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, description: "Funded publications", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, description: "Funded software", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: true, description: "Funded works", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Funder"
  end

  def address
    { "type" => "postalAddress",
      "country" => object.country.to_h.fetch("name", nil) }
  end

  def publications(**args)
    Doi.query(args[:query], funder_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Text", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def datasets(**args)
    Doi.query(args[:query], funder_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Dataset", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def softwares(**args)
    Doi.query(args[:query], funder_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Software", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def works(**args)
    Doi.query(args[:query], funder_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] }).results.to_a
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
    @response ||= Doi.query(nil, funder_id: object[:id], state: "findable", page: { number: 1, size: 0 })
  end
end
