# frozen_string_literal: true

class PrefixType < BaseObject
  description "Information about prefixes"

  field :id, ID, null: false, hash_key: "prefix.id", description: "Unique identifier for each prefix"
  # field :providers, [ProviderType], null: false do
  #   argument :query, String, required: false
  #   argument :first, Int, required: false, default_value: 25
  # end

  # field :clients, [ClientType], null: false do
  #   argument :query, String, required: false
  #   argument :first, Int, required: false, default_value: 25
  # end

  def id
    object.class.name == "Prefix" ? object.prefix : object.prefix.uid
  end

  def providers(**args)
    collection = object.providers
    collection = collection.query(args[:query]) if args[:query].present?
    collection.page(1).per(args[:first])
  end

  def clients(**args)
    collection = object.clients
    collection = collection.query(args[:query]) if args[:query].present?
    collection.page(1).per(args[:first])
  end
end
