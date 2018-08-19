class ClientPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "client-prefixes"
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :created, :updated

  belongs_to :client
  belongs_to :provider
  belongs_to :provider_prefix
  belongs_to :prefix
end
