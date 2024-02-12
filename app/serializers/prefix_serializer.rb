# frozen_string_literal: true

class PrefixSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower
  set_type :prefixes
  set_id :uid

  attributes :prefix, :created_at

  attribute :prefix, &:uid

  has_many :clients, record_type: :clients
  has_many :providers, record_type: :providers
  has_many :client_prefixes, record_type: "client-prefixes"
  has_many :provider_prefixes, record_type: "provider-prefixes"
end
