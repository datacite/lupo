class ClientPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "client-prefixes"
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :created, :updated

  belongs_to :client, record_type: :clients
  belongs_to :provider, record_type: :providers
  belongs_to :provider_prefix, record_type: :prefix_providers
  belongs_to :prefix, record_type: :prefixes
end
