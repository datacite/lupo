# frozen_string_literal: true

class ProviderPrefixSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type "provider-prefixes"
  set_id :uid
  attributes :created_at, :updated_at

  belongs_to :provider, record_type: :providers
  belongs_to :prefix, record_type: :prefixes
  has_many :clients, record_type: :clients
  has_many :client_prefixes, record_type: "client-prefixes"
end
