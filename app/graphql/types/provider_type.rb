# frozen_string_literal: true

class ProviderType < BaseObject
  description "Information about providers"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each provider"
  field :name, String, null: false, description: "Provider name"
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
  field :prefixes, PrefixConnectionWithMetaType, null: false, description: "Prefixes managed by the provider", connection: true do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :clients, ClientConnectionWithMetaType, null: false, description: "Clients associated with the provider", connection: true do
    argument :query, String, required: false
    argument :year, String, required: false
    argument :software, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def country
    return {} unless object.country_code.present?
    { 
      code: object.country_code,
      name: ISO3166::Country[object.country_code].name
    }.compact
  end

  def prefixes(**args)
    collection = ProviderPrefix.joins(:provider, :prefix).where('allocator.symbol = ?', object.uid) 
    collection = collection.state(args[:state].underscore.dasherize) if args[:state].present?
    collection = collection.query(args[:query]) if args[:query].present?
    collection = collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]) if args[:year].present?
    collection
  end

  def clients(**args)
    Client.query(args[:query], provider_id: object.uid, year: args[:year], software: args[:software], page: { number: 1, size: args[:first] }).results.to_a
  end
end
