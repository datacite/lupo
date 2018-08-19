class ProviderPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "provider-prefixes"
  set_id :uid
  attributes :created, :updated

  belongs_to :provider
  belongs_to :prefix
  has_many :clients
end
