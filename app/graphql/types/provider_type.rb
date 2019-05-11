# frozen_string_literal: true

class ProviderType < BaseObject
  description "Information about members"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each member"
  field :name, String, null: false, description: "Member name"
  field :ror_id, String, null: false, description: "Research Organization Registry (ROR) identifier"
  field :description, String, null: true, description: "Description of the member"
  field :website, String, null: true, description: "Website of the member"
  field :contact_name, String, null: true, description: "Member contact name"
  field :contact_email, String, null: true, description: "Member contact email"
  field :logo_url, String, null: true, description: "URL for the member logo"
  field :region, String, null: true, description: "Geographic region where the member is located"
  field :country, String, null: true, description: "Country where the member is located"
  field :organization_type, String, null: true, description: "Type of organization"
  field :focus_area, String, null: true, description: "Field of science covered by member"
  field :joined, String, null: true, description: "Date provider joined DataCite"
  field :prefixes, PrefixConnectionWithTotalCountType, null: false, description: "Prefixes managed by the provider", connection: true, max_page_size: 100 do
    argument :query, String, required: false
    argument :state, String, required: false
    argument :year, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :clients, [ClientType], null: false, description: "Clients associated with the provider", max_page_size: 100 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def prefixes(**args)
    collection = object.provider_prefixes.joins(:prefix)
    collection = collection.state(args[:state].underscore.dasherize) if args[:state].present?
    collection = collection.query(args[:query]) if args[:query].present?
    collection = collection.where('YEAR(allocator_prefixes.created_at) = ?', args[:year]) if args[:year].present?
    collection
  end

  def clients(**args)
    Client.query(args[:query], provider_id: object.uid, page: { cursor: 1, size: args[:first] }).records
  end
end
