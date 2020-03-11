# frozen_string_literal: true

class AddressType < BaseObject
  description "Information about addresses"

  field :type, String, null: true, description: "The type."
  field :street_address, String, null: true, description: "The street address."
  field :postal_code, String, null: true, description: "The postal code."
  field :locality, String, null: true, description: "The locality in which the street address is, and which is in the region."
  field :region, String, null: true, description: "The region."
  field :country, String, null: true, description: "The country."
end
