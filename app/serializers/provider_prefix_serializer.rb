class ProviderPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "provider-prefixes"
  set_id :uid
  attributes :created, :updated

  belongs_to :provider, record_type: :providers
  belongs_to :prefix, record_type: :prefixes
end
