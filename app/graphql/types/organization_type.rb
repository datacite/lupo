# frozen_string_literal: true

class OrganizationType < BaseObject
  description "Information about organizations"

  field :id, ID, null: true, description: "ROR ID"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "The name of the organization."
  field :alternate_name, [String], null: true, description: "An alias for the organization."
  field :identifiers, [IdentifierType], null: true, description: "The identifier(s) for the organization."
  field :url, [String], null: true, hash_key: "links", description: "URL of the organization."
  field :address, AddressType, null: true, description: "Physical address of the organization."
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."

  field :datasets, DatasetConnectionWithMetaType, null: true, description: "Datasets from this organization", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, description: "Publications from this organization", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, description: "Software from this organization", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: true, description: "Works from this organization", connection: true do
    argument :query, String, required: false
    argument :user_id, String, required: false
    argument :funder_id, String, required: false
    argument :client_id, String, required: false
    argument :provider_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def alternate_name
    object.aliases + object.acronyms
  end

  def identifiers
    Array.wrap(object.id).map { |o| { "identifier_type" => "ROR", "identifier" => o } } + 
    Array.wrap(object.fund_ref).map { |o| { "identifier_type" => "fundRef", "identifier" => o } } + 
    Array.wrap(object.wikidata).map { |o| { "identifier_type" => "wikidata", "identifier" => o } } + 
    Array.wrap(object.grid).map { |o| { "identifier_type" => "grid", "identifier" => o } } + 
    Array.wrap(object.wikipedia_url).map { |o| { "identifier_type" => "wikipedia", "identifier" => o } }
  end

  def address
    { "type" => "postalAddress",
      "country" => object.country.to_h.fetch("name", nil) }
  end

  def publications(**args)
    Doi.query(args[:query], affiliation_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Text", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def datasets(**args)
    Doi.query(args[:query], affiliation_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Dataset", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def softwares(**args)
    Doi.query(args[:query], affiliation_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], resource_type_id: "Software", state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def works(**args)
    Rails.logger.info object[:id]
    Rails.logger.info args.inspect
    Doi.query(args[:query], affiliation_id: object[:id], user_id: args[:user_id], client_id: args[:client_id], provider_id: args[:provider_id], has_citations: args[:has_citations], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] }).results.to_a
  end

  def view_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.views.buckets) : 0
  end

  def download_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.downloads.buckets) : 0
  end

  def citation_count
    response.results.total.positive? ? aggregate_count(response.response.aggregations.citations.buckets) : 0
  end

  def response
    @response ||= Doi.query(nil, affiliation_id: object[:id], state: "findable", page: { number: 1, size: 0 })
  end
end
