# frozen_string_literal: true

class ProviderType < BaseObject
  description "Information about providers"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each provider"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, description: "Provider name"
  field :displayName, String, null: true, description: "Provider display name"
  field :ror_id, String, null: false, description: "Research Organization Registry (ROR) identifier"
  field :description, String, null: true, description: "Description of the provider"
  field :website, String, null: true, description: "Website of the provider"
  field :group_email, String, null: true, description: "Provider contact email"
  field :logo_url, String, null: true, description: "URL for the provider logo"
  field :region, String, null: true, description: "Geographic region where the provider is located"
  field :country, CountryType, null: true, description: "Country where the provider is located"
  field :organization_type, String, null: true, description: "Type of organization"
  field :focus_area, String, null: true, description: "Field of science covered by provider"
  field :joined, String, null: true, description: "Date provider joined DataCite"
  field :datasets, DatasetConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored datasets" do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, PublicationConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored publications"  do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :softwares, SoftwareConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored software"  do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :works, WorkConnectionWithMetaType, null: true, connection: true, max_page_size: 1000, description: "Authored works" do
    argument :query, String, required: false
    argument :client_id, String, required: false
    argument :user_id, String, required: false
    argument :has_citations, Int, required: false
    argument :has_views, Int, required: false
    argument :has_downloads, Int, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :prefixes, ProviderPrefixConnectionWithMetaType, null: true, description: "Prefixes managed by the provider", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :clients, ClientConnectionWithMetaType, null: true, description: "Clients associated with the provider", connection: true do
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

  def publications(query: nil, client_id: nil, user_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: user_id.present? ? orcid_from_url(user_id) : nil, client_id: client_id, provider_id: object.uid, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Text", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  def datasets(query: nil, client_id: nil, user_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: user_id.present? ? orcid_from_url(user_id) : nil, client_id: client_id, provider_id: object.uid, resource_type_id: "Dataset", state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  def softwares(query: nil, client_id: nil, user_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: user_id.present? ? orcid_from_url(user_id) : nil, client_id: client_id, provider_id: object.uid, has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, resource_type_id: "Software", state: "findable", page: { number: 1, size: first }).results.to_a
  end

  def works(query: nil, client_id: nil, user_id: nil, has_citations: nil, has_views: nil, has_downloads: nil, first: nil)
    Doi.query(query, user_id: user_id.present? ? orcid_from_url(user_id) : nil, client_id: client_id, provider_id: object.uid, state: "findable", has_citations: has_citations, has_views: has_views, has_downloads: has_downloads, page: { number: 1, size: first }).results.to_a
  end

  def prefixes(**args)
    ProviderPrefix.query(args[:query], provider_id: object.uid, state: args[:state], year: args[:year], page: { number: 1, size: args[:first] }).results.to_a
  end

  def clients(**args)
    Client.query(args[:query], provider_id: object.uid, year: args[:year], software: args[:software], page: { number: 1, size: args[:first] }).results.to_a
  end
end
