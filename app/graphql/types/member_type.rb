# frozen_string_literal: true

class MemberType < BaseObject
  description "Information about providers"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each provider"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "Provider name"
  field :displayName, String, null: false, description: "Provider display name"
  field :ror_id, ID, null: true, description: "Research Organization Registry (ROR) identifier"
  field :description, String, null: true, description: "Description of the provider"
  field :website, Url, null: true, description: "Website of the provider"
  field :logo_url, Url, null: true, description: "URL for the provider logo"
  field :region, String, null: true, description: "Geographic region where the provider is located"
  field :country, CountryType, null: true, description: "Country where the provider is located"
  field :organization_type, String, null: true, description: "Type of organization"
  field :focus_area, String, null: true, description: "Field of science covered by provider"
  field :joined, GraphQL::Types::ISO8601Date, null: true, description: "Date provider joined DataCite"
  field :view_count, Integer, null: true, description: "The number of views according to the Counter Code of Practice."
  field :download_count, Integer, null: true, description: "The number of downloads according to the Counter Code of Practice."
  field :citation_count, Integer, null: true, description: "The number of citations."
  
  field :datasets, DatasetConnectionType, null: true, connection: true, max_page_size: 1000, description: "Datasets by this provider." do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionType, null: true, connection: true, max_page_size: 1000, description: "Publications by this provider."  do
    argument :query, String, required: false
    argument :ids, String, required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionType, null: true, connection: true, max_page_size: 1000, description: "Software by this provider."  do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionType, null: true, connection: true, max_page_size: 1000, description: "Works by this provider." do
    argument :query, String, required: false
    argument :ids, [String], required: false
    argument :user_id, String, required: false
    argument :repository_id, String, required: false
    argument :funder_id, String, required: false
    argument :affiliation_id, String, required: false
    argument :resource_type_id, String, required: false
    argument :has_person, Boolean, required: false
    argument :has_organization, Boolean, required: false
    argument :has_funder, Boolean, required: false
    argument :has_citations, Int, required: false
    argument :has_parts, Int, required: false
    argument :has_versions, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :prefixes, MemberPrefixConnectionType, null: true, description: "Prefixes managed by the member", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :repositories, RepositoryConnectionType, null: true, description: "Repositories associated with the member", connection: true do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :software, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def type
    "Provider"
  end

  def country
    return {} unless object.country_code.present?
    { 
      code: object.country_code,
      name: ISO3166::Country[object.country_code].name
    }.compact
  end

  def publications(**args)
    args[:resource_type_id] = "Text"
    r = response(args)

    r.results.to_a
  end

  def datasets(**args)
    args[:resource_type_id] = "Dataset"
    r = response(args)

    r.results.to_a
  end

  def softwares(**args)
    args[:resource_type_id] = "Software"
    r = response(args)

    r.results.to_a
  end

  def works(**args)  
    r = response(args)

    r.results.to_a
  end

  def prefixes(**args)
    ProviderPrefix.query(args[:query], provider_id: object.uid, state: args[:state], year: args[:year], page: { number: 1, size: args[:first] }).results.to_a
  end

  def repositories(**args)
    Client.query(args[:query], provider_id: object.uid, year: args[:year], software: args[:software], page: { number: 1, size: args[:first] }).results.to_a
  end

  def view_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.views.buckets) : 0
  end

  def download_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.downloads.buckets) : 0
  end

  def citation_count
    args = { first: 0 }
    r = response(args)
    r.results.total.positive? ? aggregate_count(r.response.aggregations.citations.buckets) : 0
  end

  def response(**args)
    Doi.query(args[:query], ids: args[:ids], user_id: args[:user_id], client_id: args[:repository_id], provider_id: object.uid, funder_id: args[:funder_id], affiliation_id: args[:affiliation_id], resource_type_id: args[:resource_type_id], has_person: args[:has_person], has_funder: args[:has_funder], has_affiliation: args[:has_affiliation], has_citations: args[:has_citations], has_parts: args[:has_parts], has_versions: args[:has_versions], has_views: args[:has_views], has_downloads: args[:has_downloads], state: "findable", page: { number: 1, size: args[:first] })
  end
end
